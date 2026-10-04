using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Common.StateMachines;

public class InvalidStateTransitionException : DomainException
{
    public InvalidStateTransitionException(string entityName, string fromState, string toState)
        : base($"Invalid state transition for {entityName} from '{fromState}' to '{toState}'.", "State.InvalidTransition")
    {
    }
}

public class StateMachine<TState, TTrigger> where TState : Enum where TTrigger : Enum
{
    private readonly Dictionary<(TState State, TTrigger Trigger), TState> _transitions = new();

    public TState CurrentState { get; private set; }

    public StateMachine(TState initialState)
    {
        CurrentState = initialState;
    }

    public StateMachine<TState, TTrigger> Configure(TState fromState, TTrigger trigger, TState toState)
    {
        _transitions[(fromState, trigger)] = toState;
        return this;
    }

    public bool CanFire(TTrigger trigger) => _transitions.ContainsKey((CurrentState, trigger));

    public TState Fire(TTrigger trigger, string entityName = "Entity")
    {
        if (_transitions.TryGetValue((CurrentState, trigger), out var nextState))
        {
            CurrentState = nextState;
            return CurrentState;
        }

        throw new InvalidStateTransitionException(entityName, CurrentState.ToString(), trigger.ToString());
    }
}
