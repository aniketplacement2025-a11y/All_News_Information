# Guide: Deploying the New User Profile Function

This guide will walk you through the necessary steps to deploy the Supabase Edge Function and configure the authentication webhook. This will enable the automatic creation of user profiles upon sign-up.

**Prerequisites:**
- You must have a Supabase project created.
- You need to have Node.js and npm installed on your local machine.

---

### **Step 1: Install the Supabase CLI**

If you don't already have the Supabase CLI installed, open your terminal and run the following command. This tool is essential for managing and deploying Supabase functions.

```bash
npm install supabase --save-dev
```

---

### **Step 2: Log in to the Supabase CLI**

Next, you need to authenticate with your Supabase account. Run the following command and follow the prompts in your browser to log in.

```bash
npx supabase login
```

---

### **Step 3: Link Your Local Project to Supabase**

Now, you need to link your local repository to your remote Supabase project. This command will ask for your project's reference ID.

You can find your **Project Ref** in your Supabase project's dashboard under **Project Settings > General**.

```bash
# Replace <PROJECT_REF> with your actual project reference ID
npx supabase link --project-ref <PROJECT_REF>
```

---

### **Step 4: Set Up Environment Variables for Local Development (Optional but Recommended)**

The function requires your project's URL and `service_role_key` to interact with your Supabase database. You can set these as secrets for local testing.

You can find these values in your Supabase project's dashboard under **Project Settings > API**.

```bash
# Replace with your actual Supabase URL
npx supabase secrets set SUPABASE_URL=https://<your-project-ref>.supabase.co

# Replace with your actual Service Role Key (keep this secret!)
npx supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

---

### **Step 5: Deploy the Edge Function**

With the project linked and secrets set, you can now deploy the function. Run the following command from the root of your project:

```bash
npx supabase functions deploy create-profile-on-signup
```

This command will bundle and deploy the function to your Supabase project.

---

### **Step 6: Configure the Authentication Webhook**

The final step is to tell Supabase to trigger this function every time a new user signs up.

1.  Go to your Supabase project dashboard.
2.  Navigate to **Authentication > Webhooks**.
3.  Click **"Add a new webhook"**.
4.  In the **"Events"** section, select **"User is created"**.
5.  In the **"HTTP URL"** field, enter the URL of the function you just deployed. It will follow this format:
    `https://<your-project-ref>.supabase.co/functions/v1/create-profile-on-signup`
6.  Click **"Add webhook"** to save your changes.

---

**That's it!** Your backend is now correctly configured. New users who sign up through your Flutter app will now have their profiles created automatically and atomically.