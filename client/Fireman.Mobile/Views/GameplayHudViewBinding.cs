using Fireman.Contracts.Matches;
using Fireman.Mobile.Navigation;

namespace Fireman.Mobile.Views;

public record HudState(
    float CurrentWater,
    float MaxWater,
    int CurrentScore,
    int RescuesCount,
    float FireIntensityPercentage,
    int RemainingSeconds
);

public class GameplayHudViewBinding : IScreen
{
    public string ScreenName => "GameplayHUD";
    public bool IsActive { get; private set; }

    public HudState State { get; private set; }

    public event Action<HudState>? OnHudUpdated;
    public event Func<PlayerMovementDto, Task>? OnMovementInput;
    public event Func<FireSuppressionActionDto, Task>? OnSuppressionTriggered;

    public GameplayHudViewBinding()
    {
        State = new HudState(
            CurrentWater: 100.0f,
            MaxWater: 100.0f,
            CurrentScore: 0,
            RescuesCount: 0,
            FireIntensityPercentage: 100.0f,
            RemainingSeconds: 180
        );
    }

    public Task InitializeAsync()
    {
        return Task.CompletedTask;
    }

    public Task ShowAsync()
    {
        IsActive = true;
        OnHudUpdated?.Invoke(State);
        return Task.CompletedTask;
    }

    public Task HideAsync()
    {
        IsActive = false;
        return Task.CompletedTask;
    }

    public void UpdateHudState(HudState newState)
    {
        State = newState;
        OnHudUpdated?.Invoke(State);
    }

    public async Task HandleJoystickMoved(Guid userId, float x, float y, float z, float rotY, float speed)
    {
        if (OnMovementInput != null)
        {
            var movement = new PlayerMovementDto(userId, x, y, z, rotY, speed);
            await OnMovementInput.Invoke(movement);
        }
    }

    public async Task HandleHoseTriggerPressed(Guid userId, Guid fireInstanceId, float waterVolume, bool extinguished)
    {
        if (OnSuppressionTriggered != null)
        {
            var action = new FireSuppressionActionDto(userId, fireInstanceId, waterVolume, extinguished);
            await OnSuppressionTriggered.Invoke(action);
        }
    }
}
