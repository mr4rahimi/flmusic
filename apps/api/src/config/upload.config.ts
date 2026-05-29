import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { BadRequestException } from '@nestjs/common';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { v4: uuidv4 } = require('uuid');

export const UPLOAD_DIR = join(process.cwd(), 'uploads');

export const ALLOWED_AUDIO_TYPES = [
  'audio/mpeg',
  'audio/mp3',
  'audio/wav',
  'audio/wave',
  'audio/x-wav',
  'audio/flac',
  'audio/aac',
  'audio/ogg',
];

export const ALLOWED_IMAGE_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
];

export const audioMulterConfig = {
  storage: diskStorage({
    destination: join(UPLOAD_DIR, 'original'),
    filename: (_req: any, _file: any, cb: any) => {
      cb(null, `${uuidv4()}.tmp`);
    },
  }),
  limits: { fileSize: 100 * 1024 * 1024 },
  fileFilter: (_req: any, file: any, cb: any) => {
    if (ALLOWED_AUDIO_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new BadRequestException('Invalid audio file type'), false);
    }
  },
};

export const imageMulterConfig = {
  storage: diskStorage({
    destination: join(UPLOAD_DIR, 'covers'),
    filename: (_req: any, file: any, cb: any) => {
      const ext = extname(file.originalname);
      cb(null, `${uuidv4()}${ext}`);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req: any, file: any, cb: any) => {
    if (ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new BadRequestException('Invalid image file type'), false);
    }
  },
};
