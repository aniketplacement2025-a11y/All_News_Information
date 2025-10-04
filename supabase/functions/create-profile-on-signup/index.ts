import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Define the shape of the incoming webhook payload
interface UserData {
  id: string;
  email: string;
  user_metadata: {
    first_name?: string;
    last_name?: string;
    phone_no?: string;
  };
}

interface WebhookPayload {
  type: 'INSERT';
  table: 'users';
  record: UserData;
}

serve(async (req) => {
  try {
    // 1. Validate the request
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const payload: WebhookPayload = await req.json();
    const { record: user } = payload;

    if (!user || !user.id || !user.email) {
      throw new Error('Invalid user data received in webhook');
    }

    // 2. Create a Supabase client with the service role key
    const supabaseClient = createClient(
      // These environment variables must be set in your Supabase project settings
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 3. Insert into public.users table
    const { error: userError } = await supabaseClient
      .from('users')
      .insert({ id: user.id, email: user.email });

    if (userError) {
      console.error('Error inserting into public.users:', userError);
      throw new Error(`Failed to create user record: ${userError.message}`);
    }

    // 4. Insert into public.profiles table
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
      // Note: At this point, the user record exists but the profile does not.
      // You might want to add more robust error handling here, like deleting the user record.
      throw new Error(`Failed to create profile record: ${profileError.message}`);
    }

    console.log(`Successfully created user and profile for ${user.email}`);

    // 5. Return a success response
    return new Response(JSON.stringify({ message: 'User profile created successfully' }), {
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