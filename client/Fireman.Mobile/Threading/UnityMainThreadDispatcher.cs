using System.Collections.Concurrent;

namespace Fireman.Mobile.Threading;

public class UnityMainThreadDispatcher
{
    private static readonly ConcurrentQueue<Action> ExecutionQueue = new();
    private static UnityMainThreadDispatcher? _instance;

    public static UnityMainThreadDispatcher Instance => _instance ??= new UnityMainThreadDispatcher();

    public void Enqueue(Action action)
    {
        if (action is null) throw new ArgumentNullException(nameof(action));
        ExecutionQueue.Enqueue(action);
    }

    public Task EnqueueAsync(Action action)
    {
        var tcs = new TaskCompletionSource();
        Enqueue(() =>
        {
            try
            {
                action();
                tcs.SetResult();
            }
            catch (Exception ex)
            {
                tcs.SetException(ex);
            }
        });
        return tcs.Task;
    }

    /// <summary>
    /// Unity MonoBehaviour Update loop'undan veya oyun ana döngüsünden çağrılır.
    /// </summary>
    public void ProcessQueue()
    {
        while (ExecutionQueue.TryDequeue(out var action))
        {
            try
            {
                action();
            }
            catch (Exception)
            {
                // Engine thread izolasyonu: bir UI hatası döngüyü kırmamalı
            }
        }
    }
}
