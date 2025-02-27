// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/jballerina.java;
import ballerina/lang.'int as langint;

# Key name for `boundary` parameter in MediaType. This is needed for composite type media types.
public const string BOUNDARY = "boundary";

# Key name for `start` parameter in MediaType. This determines which part in the multipart message contains the
# payload.
public const string START = "start";

# Key name for `type` parameter in MediaType. This indicates the MIME media type of the `root` body part.
public const string TYPE = "type";

# Key name for `charset` parameter in MediaType. This indicates the character set of the body text.
public const string CHARSET = "charset";

# Default charset to be used with MIME encoding and decoding.
public const string DEFAULT_CHARSET = "UTF-8";

# Permission to be used with opening a byte channel for overflow data.
const READ_PERMISSION = "r";

# Represents `content-id` header name.
public const string CONTENT_ID = "content-id";

# Represents `content-length` header name.
public const string CONTENT_LENGTH = "content-length";

# Represents `content-type` header name.
public const string CONTENT_TYPE = "content-type";

# Represents `content-disposition` header name.
public const string CONTENT_DISPOSITION = "content-disposition";

# Represents values in `Content-Disposition` header.
#
# + fileName - Default filename for storing the body part if the receiving agent wishes to store it in an external
#              file
# + disposition - Indicates how the body part should be presented (`inline`, `attachment`, or as `form-data`)
# + name - Represents the field name in case of `multipart/form-data`
# + parameters - A set of parameters specified in the `attribute=value` notation
public class ContentDisposition {

    public string fileName = "";
    public string disposition = "";
    public string name = "";
    public map<string> parameters = {};

    # Converts the `ContentDisposition` type to a string suitable to use as the value of a corresponding MIME header.
    # ```ballerina
    # string contDisposition = contentDisposition.toString();
    # ```
    #
    # + return - The `string` representation of the `ContentDisposition` object
    public isolated function toString() returns string {
        return convertContentDispositionToString(self);
    }
}

isolated function convertContentDispositionToString(ContentDisposition contentDisposition) returns string = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.ContentDisposition"
} external;

# Describes the nature of the data in the body of a MIME entity.
#
# + primaryType - Declares the general type of data
# + subType - A specific format of the primary-type data
# + suffix - Identifies the semantics of a specific media type
# + parameters - A set of parameters specified in an `attribute=value` notation
public class MediaType {

    public string primaryType = "";
    public string subType = "";
    public string suffix = "";
    public map<string> parameters = {};

    # Gets the “primaryType/subtype+suffix” combination in a `string` format.
    # ```ballerina
    # string baseType = mediaType.getBaseType();
    # ```
    #
    # + return - Base type as a `string` from the `MediaType` struct
    public isolated function getBaseType() returns string {
        return self.primaryType + "/" + self.subType;
    }

    # Converts the media type to a `string`, which is suitable to be used as the value of a corresponding HTTP header.
    # ```ballerina
    # string mediaTypeString = mediaType.toString();
    # ```
    #
    # + return - Content type with parameters as a `string`
    public isolated function toString() returns string {
        string contentType = self.getBaseType();
        string[] arrKeys = self.parameters.keys();
        int size = arrKeys.length();
        if (size > 0) {
            contentType = contentType + "; ";
        }
        int index = 0;
        while (index < size) {
            string value = self.parameters[arrKeys[index]] ?: "";
            if (index == size - 1) {
                contentType = contentType + arrKeys[index] + "=" + value;
                break;
            } else {
                contentType = contentType + arrKeys[index] + "=" + value + ";";
                index = index + 1;
            }
        }
        return contentType;
    }
}

# Represents the headers and body of a message. This can be used to represent both the entity of a top level message
# and an entity(body part) inside of a multipart entity.
#
# + cType - Describes the data contained in the body of the entity
# + cId - Helps one body of an entity to make a reference to another
# + cLength - Represents the size of the entity
# + cDisposition - Represents values related to `Content-Disposition` header
# + headerMap - Represents the headers of the entity. Since ballerina map is case sensitive, lower case the header names
#             before adding to the map.
# + headerNames - Represents all the header names of headers according to the given case.
public class Entity {

    private MediaType? cType = ();
    private string cId = "";
    private int cLength = 0;
    private ContentDisposition? cDisposition = ();
    private map<string[]> headerMap = {};
    private string[] headerNames = [];

    # Sets the content-type to the entity.
    # ```ballerina
    # mime:InvalidContentTypeError? contentType = mimeEntity.setContentType("application/json");
    # ```
    #
    # + mediaType - Content type, which needs to be set to the entity
    # + return - `()` if successful or else an `mime:InvalidContentTypeError` in case of invalid media-type
    public isolated function setContentType(@untainted string mediaType) returns InvalidContentTypeError? {
        self.cType = check getMediaType(mediaType);
        self.setHeader(CONTENT_TYPE, mediaType);
        return;
    }

    # Gets the content type of the entity.
    # ```ballerina
    # string contentType = mimeEntity.getContentType();
    # ```
    #
    # + return - Content type as a `string`
    public isolated function getContentType() returns @tainted string {
        string contentTypeHeaderValue = "";
        var value = self.getHeader(CONTENT_TYPE);
        if (value is string) {
            contentTypeHeaderValue = value;
        }
        return contentTypeHeaderValue;
    }

    # Sets the content ID of the entity.
    # ```ballerina
    # mimeEntity.setContentId("test-id");
    # ```
    #
    # + contentId - Content ID, which needs to be set to the entity
    public isolated function setContentId(@untainted string contentId) {
        self.cId = contentId;
        self.setHeader(CONTENT_ID, contentId);
    }

    # Gets the content ID of the entity.
    # ```ballerina
    # string contentId = mimeEntity.getContentId();
    # ```
    #
    # + return - Content ID as a `string`
    public isolated function getContentId() returns @tainted string {
        string contentId = "";
        var value = self.getHeader(CONTENT_ID);
        if (value is string) {
            contentId = value;
        }
        return contentId;
    }

    # Sets the content length of the entity.
    # ```ballerina
    # mimeEntity.setContentLength(45555);
    # ```
    #
    # + contentLength - Content length, which needs to be set to the entity
    public isolated function setContentLength(@untainted int contentLength) {
        self.cLength = contentLength;
        var contentLengthStr = contentLength.toString();
        self.setHeader(CONTENT_LENGTH, contentLengthStr);
    }

    # Gets the content length of the entity.
    # ```ballerina
    # int|error contentLength = mimeEntity.getContentLength();
    # ```
    #
    # + return - Content length as an `int` or else an error in case of a failure
    public isolated function getContentLength() returns @tainted int|error {
        string contentLength = "";
        var length = self.getHeader(CONTENT_LENGTH);
        if (length is string) {
            contentLength = length;
        }
        if (contentLength == "") {
            return -1;
        } else {
            return langint:fromString(contentLength);
        }
    }

    # Sets the content disposition of the entity.
    # ```ballerina
    # mimeEntity.setContentDisposition(contentDisposition);
    # ```
    #
    # + contentDisposition - Content disposition, which needs to be set to the entity
    public isolated function setContentDisposition(ContentDisposition contentDisposition) {
        self.cDisposition = contentDisposition;
        self.setHeader(CONTENT_DISPOSITION, contentDisposition.toString());
    }

    # Gets the content disposition of the entity.
    # ```ballerina
    # mime:ContentDisposition contentDisposition = mimeEntity.getContentDisposition();
    # ```
    #
    # + return - A `ContentDisposition` object
    public isolated function getContentDisposition() returns ContentDisposition {
        string contentDispositionVal = "";
        var value = self.getHeader(CONTENT_DISPOSITION);
        if (value is string) {
            contentDispositionVal = value;
        }
        return getContentDispositionObject(contentDispositionVal);
    }

    # Sets the body of the entity with the given content. Note that any string value is set as `text/plain`. To send a
    # JSON-compatible string, set the content-type header to `application/json` or use the `setJsonPayload` method instead.
    # ```ballerina
    # mimeEntity.setBody("body string");
    # ```
    #
    # + entityBody - Entity body can be of the type `string`,`xml`,`json`,`byte[]`,`Entity[]`, or `stream<byte[], io:Error?>`
    public isolated function setBody(string|xml|json|byte[]|Entity[]|stream<byte[], io:Error?> entityBody) {
        if (entityBody is string) {
            self.setText(entityBody);
        } else if (entityBody is xml) {
            self.setXml(entityBody);
        }  else if (entityBody is byte[]) {
            self.setByteArray(entityBody);
        } else if (entityBody is json) {
            self.setJson(entityBody);
        } else if (entityBody is stream<byte[], io:Error?>) {
            self.setByteStream(entityBody);
        } else {
            self.setBodyParts(entityBody);
        }
    }

    # Sets the entity body with a given file. This method overrides any existing `content-type` headers
    # with the default content-type, which is `application/octet-stream`. This default value
    # can be overridden by passing the content type as an optional parameter.
    # ```ballerina
    # mimeEntity.setFileAsEntityBody("<file path>");
    # ```
    #
    # + filePath - Path of the file
    # + contentType - Content type to be used with the payload. This is an optional parameter.
    #                 The default value is `application/octet-stream`
    public isolated function setFileAsEntityBody(@untainted string filePath,
            string contentType = "application/octet-stream") {
        io:ReadableByteChannel byteChannel = checkpanic io:openReadableFile(filePath);
        self.setByteChannel(byteChannel, contentType = contentType);
    }

    # Sets the entity body with the given `json` content. This method overrides any existing `content-type` headers
    # with the default content-type, which is `application/json`. This default value can be overridden
    # by passing the content type as an optional parameter.
    # ```ballerina
    # mimeEntity.setJson({ "Hello": "World" });
    # ```
    #
    # + jsonContent - JSON content, which needs to be set to the entity
    # + contentType - Content type to be used with the payload. This is an optional parameter.
    #                The default value is `application/json`
    public isolated function setJson(@untainted json jsonContent, @untainted string contentType = "application/json") {
        return externSetJson(self, jsonContent, contentType);
    }

    # Extracts the JSON body from the entity.
    # ```ballerina
    # json|mime:ParserError result = entity.getJson();
    # ```
    #
    # + return - `json` data extracted from the entity body or else an `mime:ParserError` if the entity body is not a JSON
    public isolated function getJson() returns @tainted json|ParserError {
        return externGetJson(self);
    }

    # Sets the entity body with the given XML content. This method overrides any existing content-type headers
    # with the default content-type, which is `application/xml`. This default value can be overridden
    # by passing the content-type as an optional parameter.
    # ```ballerina
    # mimeEntity.setXml(xml `<hello> world </hello>`);
    # ```
    #
    # + xmlContent - XML content, which needs to be set to the entity
    # + contentType - Content type to be used with the payload. This is an optional parameter.
    #               The default value is `application/xml`
    public isolated function setXml(@untainted xml xmlContent, @untainted string contentType = "application/xml") {
        return externSetXml(self, xmlContent, contentType);
    }

    # Extracts the `xml` body from the entity.
    # ```ballerina
    # xml|mime:ParserError result = entity.getXml();
    # ```
    #
    # + return - `xml` data extracted from the entity body or else an `mime:ParserError` if the entity body is not an XML
    public isolated function getXml() returns @tainted xml|ParserError {
        return externGetXml(self);
    }

    # Sets the entity body with the given text content. This method overrides any existing content-type headers
    # with the default content-type, which is `text/plain`. This default value can be overridden
    # by passing the content type as an optional parameter.
    # ```ballerina
    # mimeEntity.setText("Hello World");
    # ```
    #
    # + textContent - Text content, which needs to be set to the entity
    # + contentType - Content type to be used with the payload. This is an optional parameter.
    #                The default value is `text/plain`
    public isolated function setText(@untainted string textContent, @untainted string contentType = "text/plain") {
        return externSetText(self, textContent, contentType);
    }

    # Extracts the text body from the entity. If the entity body is not text compatible, an error is returned.
    # ```ballerina
    # string|mime:ParserError result = entity.getText();
    # ```
    #
    # + return - `string` data extracted from the the entity body or else an `mime:ParserError` if the entity body is not
    #            text compatible
    public isolated function getText() returns @tainted string|ParserError {
        return externGetText(self);
    }

    # Sets the entity body with the given byte[] content. This method overrides any existing `content-type` headers
    # with the default content-type, which is `application/octet-stream`. This default value
    # can be overridden by passing the content type as an optional parameter.
    # ```ballerina
    # entity.setByteArray(content.toBytes());
    # ```
    #
    # + blobContent - `byte[]` content that needs to be set to the entity
    # + contentType - Content type to be used with the payload. This is an optional parameter.
    #                 The default value is `application/octet-stream`
    public isolated function setByteArray(@untainted byte[] blobContent,
                                 @untainted string contentType = "application/octet-stream") {
        return externSetByteArray(self, blobContent, contentType);
    }

    # Gets the entity body as a `byte[]` from a given entity. If the entity size is considerably large, consider
    # using the `Entity.getByteStream()` method instead.
    # ```ballerina
    # byte[]|mime:ParserError result = entity.getByteArray();
    # ```
    #
    # + return - `byte[]` data extracted from the the entity body or else a `mime:ParserError` in case of
    #            errors
    public isolated function getByteArray() returns @tainted byte[]|ParserError {
        return externGetByteArray(self);
    }

    # Sets the entity body with the given byte channel content. This method overrides any existing content-type headers
    # with the default content-type, which is `application/octet-stream`. This default value
    # can be overridden by passing the content-type as an optional parameter.
    # ```ballerina
    # entity.setByteChannel(byteChannel);
    # ```
    #
    # + byteChannel - Byte channel, which needs to be set to the entity
    # + contentType - Content-type to be used with the payload. This is an optional parameter.
    #                 The `application/octet-stream` is the default value
    isolated function setByteChannel(io:ReadableByteChannel byteChannel,
                                   @untainted string contentType = "application/octet-stream") {
        return externSetByteChannel(self, byteChannel, contentType);
    }

    # Sets the entity body with the given byte stream content. This method overrides any existing content-type headers
    # with the default content-type, which is `application/octet-stream`. This default value
    # can be overridden by passing the content-type as an optional parameter.
    # ```ballerina
    # entity.setByteStream(byteStream);
    # ```
    #
    # + byteStream - Byte stream, which needs to be set to the entity
    # + contentType - Content-type to be used with the payload. This is an optional parameter.
    #                 The `application/octet-stream` is the default value
    public isolated function setByteStream(stream<byte[], io:Error?> byteStream,
                                   @untainted string contentType = "application/octet-stream") {
        return externSetByteStream(self, byteStream, contentType);
    }

    # Gets the entity body as a byte channel from a given entity.
    # ```ballerina
    # io:ReadableByteChannel|mime:ParserError result = entity.getByteChannel();
    # ```
    #
    # + return - An `io:ReadableByteChannel` or else a `mime:ParserError` record will be returned in case of errors
    isolated function getByteChannel() returns @tainted io:ReadableByteChannel|ParserError {
        return externGetByteChannel(self);
    }

    # Gets the entity body as a stream of `byte[]` from a given entity.
    # ```ballerina
    # stream<byte[], io:Error?>|mime:ParserError str = entity.getByteStream();
    # ```
    #
    # + arraySize - A defaultable parameter to state the size of the byte array. The default size is 8KB
    # + return - A byte stream from which the payload can be read or `mime:ParserError` in case of errors
    public isolated function getByteStream(int arraySize = 8192) returns @tainted stream<byte[], io:Error?>|ParserError {
        var value = externGetByteStream(self);
        if (value is ()) {
            ByteStream byteStream  = new(self, arraySize);
            return new stream<byte[], io:Error?>(byteStream);
        } else {
            return value;
        }
    }

    # Gets the body parts from a given entity.
    # ```ballerina
    # mime:Entity[]|mime:ParserError result = multipartEntity.getBodyParts();
    # ```
    #
    # + return - An array of body parts(`Entity[]`) extracted from the entity body or else a `mime:ParserError` if the
    #            entity body is not a set of the body parts
    public isolated function getBodyParts() returns Entity[]|ParserError {
        return externGetBodyParts(self);
    }

    # Gets the body parts as a byte channel from a given entity.
    # ```ballerina
    # io:ReadableByteChannel|mime:ParserError result = multipartEntity.getBodyPartsAsChannel();
    # ```
    #
    # + return - Body parts as a byte channel
    isolated function getBodyPartsAsChannel() returns @tainted io:ReadableByteChannel|ParserError {
        return externGetBodyPartsAsChannel(self);
    }

    # Gets the body parts as a byte stream from a given entity.
    # ```ballerina
    # stream<byte[], io:Error?>|mime:ParserError str = multipartEntity.getBodyPartsAsStream();
    # ```
    #
    # + arraySize - A defaultable paramerter to state the size of the byte array. Default size is 8KB
    # + return - Body parts as a byte stream
    public isolated function getBodyPartsAsStream(int arraySize = 8192) returns @tainted stream<byte[], io:Error?>|ParserError {
        var value = externGetBodyPartsAsStream(self);
        if (value is ()) {
            ByteStream byteStream  = new(self, arraySize);
            return new stream<byte[], io:Error?>(byteStream);
        } else {
            return value;
        }
    }

    # Sets the body parts to the entity. This method overrides any existing `content-type` headers
    # with the default `multipart/form-data` content-type. The default `multipart/form-data` value can be overridden
    # by passing the content type as an optional parameter.
    # ```ballerina
    # multipartEntity.setBodyParts(bodyParts, contentType);
    # ```
    #
    # + bodyParts - Body parts, which need to be set to the entity
    # + contentType - Content-type to be used with the payload. This is an optional parameter.
    #                The default value is `multipart/form-data`.
    public isolated function setBodyParts(@untainted Entity[] bodyParts,
                                 @untainted string contentType = "multipart/form-data") {
        return externSetBodyParts(self, bodyParts, contentType);
    }

    # Gets the header value associated with the given header name.
    # ```ballerina
    # string|mime:HeaderNotFoundError headerName = mimeEntity.getHeader(mime:CONTENT_LENGTH);
    # ```
    #
    # + headerName - Header name
    # + return - Header value associated with the given header name as a `string`. If multiple header values are
    #            present, then the first value is returned. The `HeaderNotFoundError` is returned if the header is not
    #            found
    public isolated function getHeader(@untainted string headerName) returns @tainted string|HeaderNotFoundError {
        string[]|HeaderNotFoundError value = self.getHeaders(headerName.toLowerAscii());
        if (value is string[]) {
            return value[0];
        } else {
            return value;
        }
    }

    # Gets all the header values associated with the given header name.
    # ```ballerina
    # string[]|mime:HeaderNotFoundError headerNames = mimeEntity.getHeaders(mime:CONTENT_TYPE);
    # ```
    #
    # + headerName - Header name
    # + return - All the header values associated with the given header name as a `string[]` or the
    #            `HeaderNotFoundError` if the header is not found
    public isolated function getHeaders(@untainted string headerName) returns @tainted string[]|HeaderNotFoundError {
        string lowerCaseHeaderName = headerName.toLowerAscii();
        string[]? value = self.headerMap[lowerCaseHeaderName];
        if (value is ()) {
            return error HeaderNotFoundError("Http header does not exist");
        } else {
            return value;
        }
    }

    # Gets all the header names.
    # ```ballerina
    # string[] headerNames = mimeEntity.getHeaderNames();
    # ```
    #
    # + return - All header names as a `string[]`
    public isolated function getHeaderNames() returns @tainted string[] {
        return self.headerNames.clone();
    }

    # Adds the given header value against the given header. Panic if an illegal header is passed.
    # ```ballerina
    # mimeEntity.addHeader("custom-header", "header-value");
    # ```
    #
    # + headerName - Header name
    # + headerValue - The header value to be added
    public isolated function addHeader(@untainted string headerName, string headerValue) {
        string lowerCaseHeaderName = headerName.toLowerAscii();
        var headerList = self.getHeaders(lowerCaseHeaderName);
        if (headerList is string[]) {
            headerList.push(headerValue);
        } else {
            self.setHeader(headerName, headerValue);
        }
    }

    # Sets the given header value against the existing header. If a header already exists, its value is replaced
    # with the given header value. Panic if an illegal header is passed.
    # ```ballerina
    # mimeEntity.setHeader("custom-header", "header-value");
    # ```
    #
    # + headerName - Header name
    # + headerValue - Header value
    public isolated function setHeader(@untainted string headerName, string headerValue) {
        string[] value = [headerValue];
        self.headerMap[headerName.toLowerAscii()] = value;

        // add header name to the array
        string? caseSensitiveValue = getCaseSensitiveHeaderName(self.headerNames, headerName);
        if caseSensitiveValue is () {
            self.headerNames.push(headerName);
        }
    }

    # Removes the given header from the entity.
    # ```ballerina
    # mimeEntity.removeHeader("custom-header");
    # ```
    #
    # + headerName - Header name
    public isolated function removeHeader(@untainted string headerName) {
        if !(self.hasHeader(headerName)) {
            return;
        }
        _ = self.headerMap.remove(headerName.toLowerAscii());

        // remove header name from the array
        string? caseSensitiveValue = getCaseSensitiveHeaderName(self.headerNames, headerName);
        if caseSensitiveValue is () {
            return;
        }
        int? removeIndex = self.headerNames.indexOf(<string>caseSensitiveValue);
        if removeIndex is int {
            _ = self.headerNames.remove(removeIndex);
        }
    }

    # Removes all headers associated with the entity.
    # ```ballerina
    # mimeEntity.removeAllHeaders();
    # ```
    public isolated function removeAllHeaders() {
        self.headerMap = {};
        self.headerNames.removeAll();
    }

    # Checks whether the requested header key exists in the header map.
    # ```ballerina
    # boolean res = mimeEntity.hasHeader("custom-header");
    # ```
    #
    # + headerName - Header name
    # + return - `true` if the specified header key exists
    public isolated function hasHeader(@untainted string headerName) returns boolean {
        return self.headerMap.hasKey(headerName.toLowerAscii());
    }
}

isolated function externSetJson(Entity entity, json jsonContent, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setJson"
} external;

isolated function externGetJson(Entity entity) returns @tainted json|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeDataSourceBuilder",
    name: "getJson"
} external;

isolated function externSetXml(Entity entity, xml xmlContent, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setXml"
} external;

isolated function externGetXml(Entity entity) returns @tainted xml|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeDataSourceBuilder",
    name: "getXml"
} external;

isolated function externSetText(Entity entity, string textContent, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setText"
} external;

isolated function externGetText(Entity entity) returns @tainted string|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeDataSourceBuilder",
    name: "getText"
} external;

isolated function externSetByteArray(Entity entity, byte[] byteArray, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setByteArray"
} external;

isolated function externGetByteArray(Entity entity) returns @tainted byte[]|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeDataSourceBuilder",
    name: "getByteArray"
} external;

isolated function externSetByteChannel(Entity entity, io:ReadableByteChannel byteChannel, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setByteChannel"
} external;

isolated function externSetByteStream(Entity entity, stream<byte[], io:Error?> byteStream, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setByteStream"
} external;

isolated function externGetByteChannel(Entity entity) returns @tainted io:ReadableByteChannel|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "getByteChannel"
} external;

isolated function externGetByteStream(Entity entity) returns @tainted stream<byte[], io:Error?>|ParserError? = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "getByteStream"
} external;

isolated function externSetBodyParts(Entity entity, Entity[] bodyParts, string contentType) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "setBodyParts"
} external;

isolated function externGetBodyParts(Entity entity) returns Entity[]|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "getBodyParts"
} external;

isolated function externGetBodyPartsAsChannel(Entity entity) returns @tainted io:ReadableByteChannel|ParserError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "getBodyPartsAsChannel"
} external;

isolated function externGetBodyPartsAsStream(Entity entity) returns @tainted ParserError? = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "getBodyPartsAsStream"
} external;

# Encodes a given input with MIME specific Base64 encoding scheme.
#
# + contentToBeEncoded - Content that needs to be encoded can be of type `string`, `byte[]` or `io:ReadableByteChannel`
# + charset - Charset to be used. This is used only with the string input
# + return - An encoded `string` if the given input is of type string, an encoded `byte[]` if the given input is of
#            type byte[], an encoded `io:ReadableByteChannel` if the given input is of type `io:ReadableByteChannel`,
#            or else a `mime:EncodeError` record in case of errors
public isolated function base64Encode((string|byte[]|io:ReadableByteChannel) contentToBeEncoded, string charset = "utf-8")
                returns (string|byte[]|io:ReadableByteChannel|EncodeError) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeBase64",
    name: "base64Encode"
} external;

# Decodes a given input with MIME specific Base64 encoding scheme.
#
# + contentToBeDecoded - Content that needs to be decoded can be of type `string`, `byte[]` or `io:ReadableByteChannel`
# + charset - Charset to be used. This is used only with the string input
# + return - A decoded `string` if the given input is of type string, a decoded `byte[]` if the given input is of
#            type byte[], a decoded `io:ReadableByteChannel` if the given input is of type io:ReadableByteChannel
#            or else a `mime:DecodeError` in case of errors
public isolated function base64Decode((string|byte[]|io:ReadableByteChannel) contentToBeDecoded, string charset = "utf-8")
    returns (string|byte[]|io:ReadableByteChannel|DecodeError) = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeBase64",
    name: "base64Decode"
} external;

# Encodes a given byte[] using the Base64 encoding scheme.
#
# + valueToBeEncoded - Content, which needs to be encoded
# + return - An encoded byte[] or else a `mime:EncodeError` record in case of errors
public isolated function base64EncodeBlob(byte[] valueToBeEncoded) returns byte[]|EncodeError {
    var result = base64Encode(valueToBeEncoded);
    if (result is byte[]|EncodeError) {
        return result;
    } else {
        return error EncodeError("Error occurred while encoding byte[]");
    }
}

# Decodes a given byte[] using the Base64 encoding scheme.
#
# + valueToBeDecoded - Content, which needs to be decoded
# + return - A decoded `byte[]` or else a `mime:DecodeError` record in case of errors
public isolated function base64DecodeBlob(byte[] valueToBeDecoded) returns byte[]|DecodeError {
    var result = base64Decode(valueToBeDecoded);
    if (result is byte[]|DecodeError) {
        return result;
    } else {
        return error DecodeError("Error occurred while decoding byte[]");
    }
}

isolated function getCaseSensitiveHeaderName(string[] headerNames, string headerName) returns string? {
    foreach string name in headerNames {
        if (name.toLowerAscii() == headerName.toLowerAscii()) {
            return name;
        }
    }
    return;
}

# Gets the `MediaType` object populated with it when the `Content-Type` is in string.
# ```ballerina
# mime:MediaType|mime:InvalidContentTypeError returnVal = getMediaType("custom-header");
# ```
#
# + contentType - Content-Type in string
# + return - `MediaType` object or else a `mime:InvalidContentTypeError` in case of an invalid content-type
public isolated function getMediaType(string contentType) returns MediaType|InvalidContentTypeError = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.MimeEntityBody",
    name: "getMediaType"
} external;

# Given the Content-Disposition as a string, gets the `ContentDisposition` object with it.
# ```ballerina
# mime:ContentDisposition cDisposition = getContentDispositionObject("form-data; name=filepart; filename=file-01.txt");
# ```
#
# + contentDisposition - Content disposition string
# + return - A `ContentDisposition` object
public isolated function getContentDispositionObject(string contentDisposition) returns ContentDisposition = @java:Method {
    'class: "io.ballerina.stdlib.mime.nativeimpl.ContentDisposition",
    name: "getContentDispositionObject"
} external;
