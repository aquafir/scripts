--Get current DateTime: https://learn.microsoft.com/en-us/dotnet/api/system.datetime?view=net-7.0
local now = DateTime.UtcNow
print(now)
--

--Get a TimeSpan: https://learn.microsoft.com/en-us/dotnet/api/system.timespan?view=net-7.0
sleep(1000)
local span = DateTime.UtcNow - now
span = span + TimeSpan.FromSeconds(-1)
span = span.Add(TimeSpan.FromMinutes(1))
print(span.TotalSeconds)

