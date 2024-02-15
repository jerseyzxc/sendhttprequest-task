# Send HTTP Request Task

![logo](https://github.com/jerseyzxc/sendhttprequest-task/assets/118034690/d533891f-e328-4249-9120-69582cdcfc88)

# Description

This task allows you to perform an HTTP request to an API within a pipeline.

# Documentation

1. Choose correct HTTP verb
2. Define Headers in JSON format for the request
3. Enter the URL including any query parameters
4. Specify body payload for POST/PUT/PATCH requests in JSON format

# Proxy
- If the request needs to be sent via proxy, you can specify proxy URL (make sure to include http://)
- Proxy credentials can also be provided (username and/or password)

# Output
- The task outputs two variables: 'responseBody' and 'statusCode' which can be used in subsequent tasks.
