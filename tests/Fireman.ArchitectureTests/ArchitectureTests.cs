using System.Reflection;
using Fireman.Api.Controllers;
using Fireman.Application.Auth;
using Fireman.Domain.Users;
using Fireman.Infrastructure.Persistence;
using Fireman.Shared.Enums;
using Xunit;

namespace Fireman.ArchitectureTests;

public class ArchitectureTests
{
    [Fact]
    public void DomainAssembly_ShouldNotReferenceInfrastructureOrApi()
    {
        var domainAssembly = typeof(User).Assembly;
        var referencedAssemblies = domainAssembly.GetReferencedAssemblies()
            .Select(a => a.Name)
            .ToList();

        Assert.DoesNotContain("Fireman.Infrastructure", referencedAssemblies);
        Assert.DoesNotContain("Fireman.Api", referencedAssemblies);
        Assert.DoesNotContain("Fireman.Application", referencedAssemblies);
    }

    [Fact]
    public void ApplicationAssembly_ShouldNotReferenceInfrastructureOrApi()
    {
        var applicationAssembly = typeof(AuthService).Assembly;
        var referencedAssemblies = applicationAssembly.GetReferencedAssemblies()
            .Select(a => a.Name)
            .ToList();

        Assert.DoesNotContain("Fireman.Infrastructure", referencedAssemblies);
        Assert.DoesNotContain("Fireman.Api", referencedAssemblies);
    }

    [Fact]
    public void AllEnumsInShared_ShouldBeTrueEnums()
    {
        var sharedAssembly = typeof(UserRole).Assembly;
        var enumTypes = sharedAssembly.GetTypes()
            .Where(t => t.Namespace == "Fireman.Shared.Enums")
            .ToList();

        Assert.NotEmpty(enumTypes);
        foreach (var type in enumTypes)
        {
            Assert.True(type.IsEnum, $"Type {type.Name} in Fireman.Shared.Enums is not an enum.");
        }
    }

    [Fact]
    public void AllControllersInApi_ShouldInheritFromBaseApiController()
    {
        var apiAssembly = typeof(BaseApiController).Assembly;
        var controllerTypes = apiAssembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && t.Name.EndsWith("Controller"))
            .ToList();

        Assert.NotEmpty(controllerTypes);
        foreach (var controller in controllerTypes)
        {
            Assert.True(
                typeof(BaseApiController).IsAssignableFrom(controller),
                $"Controller {controller.Name} does not inherit from BaseApiController.");
        }
    }
}
