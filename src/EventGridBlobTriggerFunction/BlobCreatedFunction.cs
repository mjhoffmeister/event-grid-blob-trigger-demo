using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

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
            [BlobTrigger("event-container/{name}", Source = BlobTriggerSource.EventGrid, Connection = "BlobServiceUri")] Stream stream,
            string name)
        {
            using var blobStreamReader = new StreamReader(stream);
            var content = await blobStreamReader.ReadToEndAsync();
            _logger.LogInformation(
                "C# Blob Trigger (using Event Grid) processed blob {@BlobInfo}",
                new { Timestamp = DateTime.UtcNow("o"), Name = name });
        }
    }
}
