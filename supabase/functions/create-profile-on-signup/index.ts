import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// The shape of the auth.user.created webhook payload
interface AuthUser {
  id: string;
  email: string;
  user_metadata: {
    first_name?: string;
    last_name?: string;
    phone_no?: string;
  };
}

interface AuthWebhookPayload {
  type: 'auth.user.created';
  record: AuthUser;
}

serve(async (req) => {
  try {
    // 1. Validate the request method
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 2. Parse the request body
    const payload: AuthWebhookPayload = await req.json();
    const { record: user } = payload;

    // Validate the payload
    if (payload.type !== 'auth.user.created' || !user || !user.id || !user.email) {
      throw new Error('Invalid auth webhook payload received');
    }

    // 3. Create a Supabase client with the service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 4. Insert into public.users table
    const { error: userError } = await supabaseClient
      .from('users')
      .insert({
        id: user.id,
        email: user.email,
      });

    if (userError) {
      console.error('Error inserting into public.users:', userError);
      throw new Error(`Failed to create user record: ${userError.message}`);
    }

    // 5. Insert into public.profiles table
    const { error: profileError } = await supabaseClient
      .from('profiles')
      .insert({
        email: user.email,
        first_name: user.user_metadata?.first_name,
        last_name: user.user_metadata?.last_name,
        phone_no: user.user_metadata?.phone_no,
      });

    if (profileError) {
      console.error('Error inserting into public.profiles:', profileError);
      // If profile creation fails, clean up the user record that was just created.
      await supabaseClient.from('users').delete().eq('id', user.id);
      throw new Error(`Failed to create profile record: ${profileError.message}`);
    }

    console.log(`Successfully created user and profile for ${user.email}`);

    // 6. Return a success response
    return new Response(JSON.stringify({ message: 'User and profile created successfully' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Function Error:', error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});