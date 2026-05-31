FROM node:22-alpine

# نصب ffmpeg
RUN apk add --no-cache ffmpeg

# نصب pnpm
RUN npm install -g pnpm

WORKDIR /app

# کپی فایل‌های dependency
COPY package.json pnpm-lock.yaml ./

# نصب dependencies
RUN pnpm install --frozen-lockfile --prod

# کپی source code
COPY . .

# build
RUN pnpm build

# پوشه uploads
RUN mkdir -p uploads/original uploads/processed uploads/covers uploads/waveforms

EXPOSE 3000

CMD ["node", "dist/main.js"]
