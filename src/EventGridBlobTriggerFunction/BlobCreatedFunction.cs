using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Functions.Worker.Http;

namespace EventGridBlobTriggerFunction
{
    public class BlobCreatedFunction
    {
        private readonly ILogger _logger;

        public BlobCreatedFunction(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<BlobCreatedFunction>();
        }

        [Function(nameof(EventGridBlobTriggerFunction))]
        public async Task Run(
            [BlobTrigger("demo/{name}", Source = BlobTriggerSource.EventGrid, Connection = "BlobServiceUri")] Stream stream,
            string name)
        {
            using var blobStreamReader = new StreamReader(stream);
            var content = await blobStreamReader.ReadToEndAsync();
            _logger.LogInformation(
                "C# Blob Trigger (using Event Grid) processed blob {@BlobInfo}",
                new { Timestamp = DateTime.UtcNow, Name = name });
        }
    }

    public class HelloWorldFunction
    {
        private readonly ILogger _logger;

        public HelloWorldFunction(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<HelloWorldFunction>();
        }

        [Function("HelloWorld")]
        public async Task<HttpResponseData> RunHelloWorld(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            _logger.LogInformation("HelloWorld function was triggered.");
            var response = req.CreateResponse(System.Net.HttpStatusCode.OK);
            await response.WriteStringAsync("Hello World");
            return response;
        }
    }
}
