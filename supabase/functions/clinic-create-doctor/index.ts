import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return json(
        {
          error: 'Supabase server configuration is missing.',
        },
        500,
      );
    }

    const authHeader = req.headers.get('Authorization');

    if (!authHeader) {
      return json(
        {
          error: 'Authorization header is required.',
        },
        401,
      );
    }

    finalClientCheck();

    finalClientCheck;

    const admin = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    // ---------------------------------------------------------
    // 1. Verify the currently logged-in clinic
    // ---------------------------------------------------------

    const token = authHeader.replace(/^Bearer\s+/i, '');

    const {
      data: userData,
      error: userError,
    } = await admin.auth.getUser(token);

    if (userError || !userData.user) {
      return json(
        {
          error:
            'Invalid clinic session. Please login again.',
        },
        401,
      );
    }

    const clinicId = userData.user.id;

    console.log(
      'Clinic creating doctor:',
      clinicId,
    );

    const {
      data: clinicProfile,
      error: clinicProfileError,
    } = await admin
      .from('profiles')
      .select('id, role')
      .eq('id', clinicId)
      .maybeSingle();

    if (clinicProfileError) {
      throw new Error(
        `Clinic profile lookup failed: ${clinicProfileError.message}`,
      );
    }

    if (
      !clinicProfile ||
      clinicProfile.role !== 'clinic'
    ) {
      return json(
        {
          error:
            'Only clinic accounts can create doctor accounts.',
        },
        403,
      );
    }

    // ---------------------------------------------------------
    // 2. Read request
    // ---------------------------------------------------------

    const body = await req.json();

    const name = String(
      body.name ?? '',
    ).trim();

    const email = String(
      body.email ?? '',
    ).trim().toLowerCase();

    const password = String(
      body.password ?? '',
    );

    const specialization = String(
      body.specialization ?? '',
    ).trim();

    const qualification = String(
      body.qualification ?? '',
    ).trim();

    const phone = String(
      body.phone ?? '',
    ).trim();

    if (
      !name ||
      !email ||
      !password ||
      !specialization ||
      !qualification ||
      !phone
    ) {
      return json(
        {
          error:
            'All doctor fields are required.',
        },
        400,
      );
    }

    if (password.length < 8) {
      return json(
        {
          error:
            'Password must contain at least 8 characters.',
        },
        400,
      );
    }

    console.log(
      'Creating doctor Auth account:',
      email,
    );

    // ---------------------------------------------------------
    // 3. Create Supabase Auth user
    // ---------------------------------------------------------

    const {
      data: created,
      error: createError,
    } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: name,
        role: 'doctor',
        phone,
        specialization,
        qualification,
      },
    });

    if (createError || !created.user) {
      return json(
        {
          error:
            createError?.message ??
            'Could not create doctor account.',
        },
        400,
      );
    }

    const doctorId = created.user.id;

    console.log(
      'Doctor Auth account created:',
      doctorId,
    );

    try {
      // -------------------------------------------------------
      // 4. IMPORTANT:
      // The CareFlow database automatically creates the
      // profiles row when the Auth user is created.
      //
      // Therefore DO NOT INSERT another profiles row.
      // Update the existing row instead.
      // -------------------------------------------------------

      console.log(
        'Updating automatically-created doctor profile:',
        doctorId,
      );

      const {
        data: updatedProfile,
        error: profileError,
      } = await admin
        .from('profiles')
        .update({
          full_name: name,
          role: 'doctor',
          phone,
          specialization,
          qualification,
        })
        .eq('id', doctorId)
        .select('id')
        .maybeSingle();

      if (profileError) {
        throw new Error(
          `Doctor profile update failed: ${profileError.message}`,
        );
      }

      if (!updatedProfile) {
        throw new Error(
          'Doctor Auth account was created, but the automatic profiles row was not found.',
        );
      }

      console.log(
        'Doctor profile updated successfully.',
      );

      // -------------------------------------------------------
      // 5. Connect doctor to this clinic
      // -------------------------------------------------------

      console.log(
        'Creating clinic_doctors relationship...',
      );

      const {
        error: clinicDoctorError,
      } = await admin
        .from('clinic_doctors')
        .insert({
          clinic_id: clinicId,
          doctor_id: doctorId,
          active: true,
        });

      if (clinicDoctorError) {
        throw new Error(
          `Clinic-doctor relationship failed: ${clinicDoctorError.message}`,
        );
      }

      console.log(
        'Clinic-doctor relationship created.',
      );

    } catch (dbError) {
      console.error(
        'Doctor setup failed:',
        dbError,
      );

      // Roll back Auth user if database setup fails.
      await admin.auth.admin.deleteUser(
        doctorId,
      );

      throw dbError;
    }

    // ---------------------------------------------------------
    // 6. Success
    // ---------------------------------------------------------

    return json({
      success: true,
      message:
        'Doctor account created successfully.',
      doctor_id: doctorId,
      user_id: doctorId,
    });

  } catch (error) {
    console.error(
      'clinic-create-doctor error:',
      error,
    );

    return json(
      {
        error:
          error instanceof Error
            ? error.message
            : String(error),
      },
      500,
    );
  }
});

function finalClientCheck() {
  // Intentionally empty.
  // Keeps the Edge Function initialization explicit.
}

function json(
  data: Record<string, unknown>,
  status = 200,
) {
  return new Response(
    JSON.stringify(data),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    },
  );
}