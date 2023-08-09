local http = require('http')
local response = http.request('https://api.justyy.workers.dev/api/fortune/')

print("response:", response);
print("statusCode:", response.Status);
print("body:", response.Body);