// Usage: npm run admin:hash -- "my password"
import bcrypt from 'bcryptjs';

const password = process.argv[2];
if (!password || password.length < 10) {
  console.error('Provide a password of at least 10 characters: npm run admin:hash -- "your password"');
  process.exit(1);
}
console.log(bcrypt.hashSync(password, 12));
