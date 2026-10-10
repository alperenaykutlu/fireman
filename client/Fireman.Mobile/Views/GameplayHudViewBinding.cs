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
    public event Func<PlayerInputDto, Task>? OnMovementInput;
    public event Func<PlayerInputDto, Task>? OnBombTriggered;

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

    public async Task HandleMovementInput(Guid matchId, Guid userId, long seq, byte moveDir)
    {
        if (OnMovementInput != null)
        {
            var input = new PlayerInputDto(matchId, userId, seq, seq, moveDir, PlaceBomb: false, SubTileX: 0, SubTileY: 0);
            await OnMovementInput.Invoke(input);
        }
    }

    public async Task HandlePlaceBombPressed(Guid matchId, Guid userId, long seq)
    {
        if (OnBombTriggered != null)
        {
            var input = new PlayerInputDto(matchId, userId, seq, seq, MoveDir: 0, PlaceBomb: true, SubTileX: 0, SubTileY: 0);
            await OnBombTriggered.Invoke(input);
        }
    }
}
