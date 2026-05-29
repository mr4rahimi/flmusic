import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength, MaxLength } from 'class-validator';

export class CreateCommentDto {
  @ApiProperty({ example: 'آهنگ فوق‌العاده‌ایه!' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  content: string;
}
