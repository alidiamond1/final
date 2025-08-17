# Backend Deployment Guide

## Vercel-ka Deploy gareynta

### 1. Environment Variables

Vercel dashboard-ka ku dar environment variables kuwan:

```
MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/database-name
PORT=3000
NODE_ENV=production
JWT_SECRET=your-jwt-secret-key-here
```

### 2. Deployment Steps

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel:**
   ```bash
   vercel login
   ```

3. **Deploy:**
   ```bash
   vercel --prod
   ```

### 3. Environment Variables Setup

1. Go to your Vercel dashboard
2. Select your project
3. Go to Settings → Environment Variables
4. Add the following variables:
   - `MONGO_URL`: Your MongoDB Atlas connection string
   - `JWT_SECRET`: A strong random string for JWT tokens
   - `NODE_ENV`: production

### 4. MongoDB Atlas Setup (Required)

Since Vercel is serverless, you need MongoDB Atlas (cloud database):

1. Go to https://cloud.mongodb.com
2. Create a cluster
3. Create a database user
4. Whitelist IP addresses (0.0.0.0/0 for all IPs)
5. Get connection string and use it as MONGO_URL

### 5. Domain

After deployment, your API will be available at:
`https://your-project-name.vercel.app/api/` 