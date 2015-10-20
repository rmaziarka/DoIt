<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Validate-Deploy {
    param ($NodeName, $Environment, $Tokens, $ConnectionParams)

    $url = "http://${NodeName}:$($Tokens.WebConfig.WebsitePort)"
    Write-Log -Info "Sending HTTP GET request to '$url'"
    $result = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($result.StatusCode -ne 200) {
        throw "Web page at $url is not available - response status code: $($result.StatusCode)."
    }
    if ($result.Content -inotmatch 'id: 1, name: OrderFromDatabase') {
        throw "Web page at $url returns invalid response - does not include order information from database."
    }
    Write-Log -Info 'HTTP response contains information from database - deployment successful.'
}