using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AdminSite.Models
{
    public class JsonBase64ByteArrayConverter : JsonConverter<byte[]>
    {
        public override byte[]? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.String)
            {
                var base64 = reader.GetString();
                return base64 != null ? Convert.FromBase64String(base64) : null;
            }
            return null;
        }

        public override void Write(Utf8JsonWriter writer, byte[]? value, JsonSerializerOptions options)
        {
            if (value != null)
                writer.WriteStringValue(Convert.ToBase64String(value));
            else
                writer.WriteNullValue();
        }
    }
}
