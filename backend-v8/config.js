// MongoDB Atlas connection string (replace with your own connection string)
const MONGODB_URI = "mongodb+srv://iskele360v7:JKKW8hjxwbKWPU1T@cluster0.fbsyvhz.mongodb.net/iskele360?retryWrites=true&w=majority";

// Server port
const PORT = process.env.PORT || 5050;

// JWT Settings
const JWT_SECRET = "iskele360_super_secret_key_change_in_production";
const JWT_EXPIRES_IN = "30d";

module.exports = {
  MONGODB_URI,
  PORT,
  JWT_SECRET,
  JWT_EXPIRES_IN
}; 