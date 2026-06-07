import { IsString, IsOptional, IsIn, MinLength, MaxLength } from 'class-validator';

export class CreatePlaylistDto {
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsIn(['public', 'private'])
  visibility?: string;
}
