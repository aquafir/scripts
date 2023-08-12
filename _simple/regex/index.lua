--Regex comes from .NET: https://learn.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regex?view=net-7.0
local testRe = Regex.new("^test (?<numbers>\\d+) stuff", RegexOptions.Compiled)

print(testRe.IsMatch('not a match'))
print(testRe.IsMatch('test 456 stuff'))

local match = testRe.Match("test 123 stuff")
if match.Success then
  print("Matched number:", match.Groups["numbers"].Value)
else
  print("Did not match...")
end

testRe = Regex.new("f\\w+", RegexOptions.IgnoreCase)
local matches = testRe.Matches('FOO faa fii')
print(#matches)

for value in matches do
  print(tostring(value))
end

--Another approach to multiple matches
-- Match match = Regex.Match(input, pattern, options,
-- TimeSpan.FromSeconds(1));
-- while (match.Success) {
-- match = match.NextMatch();
-- }


--Todo: RegexOptions