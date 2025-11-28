import {
  Inject,
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { eq } from 'drizzle-orm';
import * as schema from '../db/schema.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import { UpdateUserDto } from './dto/update-user.dto.js';

@Injectable()
export class UsersService {
  constructor(
    @Inject('DRIZZLE_PROVIDER')
    private readonly db: NodePgDatabase<typeof schema>,
  ) {}

  async create(createUserDto: CreateUserDto) {
    const existingUser = await this.db
      .select()
      .from(schema.users)
      .where(eq(schema.users.email, createUserDto.email))
      .limit(1);

    if (existingUser.length > 0) {
      throw new ConflictException(
        `User with email ${createUserDto.email} already exists`,
      );
    }

    const [newUser] = await this.db
      .insert(schema.users)
      .values({
        email: createUserDto.email,
        name: createUserDto.name,
      })
      .returning();

    return newUser;
  }

  async findAll() {
    return this.db.select().from(schema.users);
  }

  async findOne(id: string) {
    const [user] = await this.db
      .select()
      .from(schema.users)
      .where(eq(schema.users.id, id))
      .limit(1);

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const user = await this.findOne(id);

    if (updateUserDto.email && updateUserDto.email !== user.email) {
      const existingUser = await this.db
        .select()
        .from(schema.users)
        .where(eq(schema.users.email, updateUserDto.email))
        .limit(1);

      if (existingUser.length > 0) {
        throw new ConflictException(
          `User with email ${updateUserDto.email} already exists`,
        );
      }
    }

    const [updatedUser] = await this.db
      .update(schema.users)
      .set({
        ...updateUserDto,
        updatedAt: new Date(),
      })
      .where(eq(schema.users.id, id))
      .returning();

    return updatedUser;
  }

  async remove(id: string) {
    await this.findOne(id);

    await this.db.delete(schema.users).where(eq(schema.users.id, id));

    return { message: `User with ID ${id} has been deleted` };
  }
}
