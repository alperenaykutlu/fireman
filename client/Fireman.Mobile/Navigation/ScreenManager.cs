namespace Fireman.Mobile.Navigation;

public class ScreenManager
{
    private readonly Dictionary<string, IScreen> _registeredScreens = new();
    private readonly Stack<IScreen> _navigationStack = new();

    public IScreen? CurrentScreen => _navigationStack.Count > 0 ? _navigationStack.Peek() : null;

    public event Action<IScreen?>? OnScreenChanged;

    public void RegisterScreen(IScreen screen)
    {
        _registeredScreens[screen.ScreenName] = screen;
    }

    public async Task NavigateToAsync(string screenName)
    {
        if (!_registeredScreens.TryGetValue(screenName, out var targetScreen))
            throw new InvalidOperationException($"Screen '{screenName}' is not registered.");

        if (CurrentScreen != null)
        {
            await CurrentScreen.HideAsync();
        }

        _navigationStack.Push(targetScreen);
        await targetScreen.InitializeAsync();
        await targetScreen.ShowAsync();

        OnScreenChanged?.Invoke(targetScreen);
    }

    public async Task GoBackAsync()
    {
        if (_navigationStack.Count <= 1)
            return;

        var current = _navigationStack.Pop();
        await current.HideAsync();

        var previous = _navigationStack.Peek();
        await previous.ShowAsync();

        OnScreenChanged?.Invoke(previous);
    }
}
