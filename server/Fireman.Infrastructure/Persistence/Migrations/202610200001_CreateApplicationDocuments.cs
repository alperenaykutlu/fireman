using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Fireman.Infrastructure.Persistence.Migrations;

[DbContext(typeof(FiremanDbContext))]
[Migration("202610200001_CreateApplicationDocuments")]
public sealed class CreateApplicationDocuments : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.CreateTable(
        name: "ApplicationDocuments",
        columns: table => new
        {
            Collection = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
            Id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
            Payload = table.Column<string>(type: "text", nullable: false),
            IndexedFields = table.Column<string>(type: "jsonb", nullable: false, defaultValue: "{}")
        },
        constraints: table => table.PrimaryKey("PK_ApplicationDocuments", x => new { x.Collection, x.Id }));

    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.DropTable(name: "ApplicationDocuments");
}
