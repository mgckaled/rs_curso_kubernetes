CREATE TABLE "operation_logs" (
	"id" text PRIMARY KEY NOT NULL,
	"operation" text NOT NULL,
	"endpoint" text NOT NULL,
	"status_code" integer NOT NULL,
	"duration" integer NOT NULL,
	"timestamp" timestamp DEFAULT now() NOT NULL,
	"metadata" text
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" text PRIMARY KEY NOT NULL,
	"email" text NOT NULL,
	"name" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
