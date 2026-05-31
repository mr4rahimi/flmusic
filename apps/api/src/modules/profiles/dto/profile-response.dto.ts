import { ApiProperty } from '@nestjs/swagger';
import { UserRole, VerifiedStatus } from '../../../modules/users/user.entity';

export class ProfileResponseDto {
  @ApiProperty() id: string;
  @ApiProperty() username: string;
  @ApiProperty() email: string;
  @ApiProperty() role: UserRole;
  @ApiProperty() verifiedStatus: VerifiedStatus;
  @ApiProperty() avatarUrl: string | null;
  @ApiProperty() bio: string | null;
  @ApiProperty() followersCount: number;
  @ApiProperty() followingCount: number;
  @ApiProperty() tracksCount: number;
  @ApiProperty() isFollowing: boolean;
  @ApiProperty() createdAt: Date;
}
