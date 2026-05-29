import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  MaxLength,
  IsEnum,
  IsArray,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { TrackVisibility } from '../track.entity';

export class CreateTrackDto {
  @ApiProperty({ example: 'اسم آهنگ' })
  @IsString()
  @MaxLength(100)
  title: string;

  @ApiPropertyOptional({ example: 'توضیحات آهنگ' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ example: 'pop' })
  @IsOptional()
  @IsString()
  genre?: string;

  @ApiPropertyOptional({ example: 'pop,iranian,electronic' })
  @IsOptional()
  @Transform(({ value }) => {
    if (!value) return [];
    if (Array.isArray(value)) return value;
    return value.split(',').map((t: string) => t.trim()).filter(Boolean);
  })
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ enum: TrackVisibility })
  @IsOptional()
  @IsEnum(TrackVisibility)
  visibility?: TrackVisibility;
}
