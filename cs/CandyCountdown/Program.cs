using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

class Program
{
    static async Task Main(string[] args)
    {
        string? webhook = GetWebhookArgument(args);

        TimeZoneInfo osloTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Oslo");
        DateTime utcNow = DateTime.UtcNow;
        DateTime osloNow = TimeZoneInfo.ConvertTimeFromUtc(utcNow, osloTimeZone);
        DateTime todayAtElevenOslo = new DateTime(osloNow.Year, osloNow.Month, osloNow.Day, 11, 0, 0, DateTimeKind.Unspecified);
        DateTime todayAtElevenUtc = TimeZoneInfo.ConvertTimeToUtc(todayAtElevenOslo, osloTimeZone);

        DateTime nextFriday = todayAtElevenUtc;

        for (int offset = 0; offset <= 7; offset++)
        {
            if (offset == 0 && utcNow > todayAtElevenUtc)
            {
                continue;
            }

            DateTime candidate = todayAtElevenUtc.AddDays(offset);
            if (candidate.DayOfWeek == DayOfWeek.Friday)
            {
                nextFriday = candidate;
                break;
            }
        }

        TimeSpan span = nextFriday - utcNow;
        string message = span > new TimeSpan(6, 22, 0, 0)
            ? "Hurra!! Det er godteritid 🎉🍬🍭😊"
            : string.Format(
                "Det er {0} dag{1}, {2} time{3} og {4} minutt{5} igjen til godteri. 🍬🍭",
                span.Days,
                span.Days != 1 ? "er" : string.Empty,
                span.Hours,
                span.Hours != 1 ? "r" : string.Empty,
                span.Minutes,
                span.Minutes != 1 ? "er" : string.Empty);

        Console.WriteLine(message);

        if (string.IsNullOrWhiteSpace(webhook))
        {
            return;
        }

        var payload = new
        {
            blocks = new[]
            {
                new
                {
                    type = "section",
                    text = new
                    {
                        type = "plain_text",
                        text = message,
                        emoji = true
                    }
                }
            }
        };

        string json = JsonSerializer.Serialize(payload);

        using var client = new HttpClient();
        using var content = new StringContent(json, Encoding.UTF8, "application/json");
        using HttpResponseMessage response = await client.PostAsync(webhook, content);
        response.EnsureSuccessStatusCode();
    }

    static string? GetWebhookArgument(string[] args)
    {
        if (args.Length == 0)
        {
            return null;
        }

        if (args.Length >= 2 && string.Equals(args[0], "--webhook", StringComparison.OrdinalIgnoreCase))
        {
            return args[1];
        }

        return args[0];
    }
}
