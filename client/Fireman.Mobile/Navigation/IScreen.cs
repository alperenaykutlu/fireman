namespace Fireman.Mobile.Navigation;

public interface IScreen
{
    string ScreenName { get; }
    bool IsActive { get; }
    Task InitializeAsync();
    Task ShowAsync();
    Task HideAsync();
}
