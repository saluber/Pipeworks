function ConvertFrom-Markdown
{
    <#
    .Synopsis
        Converts from markdown to HTML format
    .Description
        Converts from the lightweight markup format Markdown into HTML
    .Link
        http://daringfireball.net/projects/markdown/
    .Link
        http://en.wikipedia.org/wiki/Markdown
    .Example
        ConvertFrom-MarkDown '
# Heading #
## Subheading
### Another Subheading ###

Header 1 
=========

Header 2
--------

***

---
*italics*
* * *
**bold**
- - -
_moreitalics_
- - -
__morebold__
******
Some text with `some code` inline 

    some code
    plain old indented code


! [Show Logo](http://show-logo.com/?Show-Logo_Text=Show-Logo&Show-Logo_RandomFont=true)
! [Show Logo][2]

[wikipedia](http://wikipedia.org)

[start-automating][1]
[start-automating][]
--------

[1]: http://start-automating.com/
[2]: http://show-logo.com/?Show-Logo_Text=Show-Logo&Show-Logo_RandomFont=true
[start-automating]: http://start-automating.com/

'    

    #>
    [OutputType([string])]
    param(
    # The Markdown text that will be converted into HTML
    #|LinesForInput 20
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [Alias('Md')]
    [String]$Markdown,
    
    [Parameter(Position=1)]
    # If set, will convert links to Write-Link.  
    # This will automatically embed richer content
    #|Float
    [Switch]$ConvertLink,
    
    [Parameter(Position=3)]
    # If set, will convert PRE tag content into colorized PowerShell     
    [Switch]$ScriptAsPowerShell,
    
    [Parameter(Position=2)]
    # If set, will recognize @{} as an embedded object, and will show the data in that object with Out-HTML.          
    #|Float
    [Switch]$ShowData,

    # If set, will splat embedded data to run commands    
    [Switch]$Splat
    )
    
    process {
        
        
        if ($ShowData) {
            $markdown  = [Regex]::Replace($markdown, 
                "\`$(\w{1,})", 
                {

                        
                    $text = $args[0].Groups[1].ToString()
                    if ($text -ieq 'pipeworksmanifest') {
                        return ('$' + $args[0].Groups[1])
                        
                    }

                    # If it's castable to a double, it's probably a currency, not a variable
                    if ($text -as [Double]) {
                        return ('$' + $text)
                    }

                    if ($text -ieq 'true') {
                        return ('$' + $true)
                    }

                    if ($text -ieq 'false') {
                        return ('$' + $false)
                    }

                    if ($text -like "*username*" -or 
                        $text -like "*password*" -or 
                        $text -like "*secret*" -or 
                        $Text -like "*key*" -or 
                        $text -eq "home") {
                        return ('$' +$args[0].Groups[1])                        
                    }

                    $v = $ExecutionContext.SessionState.PSVariable.Get($text)
                    
                    if ($v) {
                        if ($v.Value -is [string] -or 
                            $v.Value -is [int] -or 
                            $v.Value -is [float]) {
                            $scriptHtml = $v.Value
                        } else {
                            $scriptHtml = $v.Value | Out-HTML
                        }
                    } else {
                        $scriptHtml =""
                    }


                    if ($scriptHtml) {
                        $scriptHtml
                    } else {
                        if ($debugPreference -ne 'SilentlyContinue') {
                            return ('$' + $args[0].Groups[1])
                        } else {
                            return ' ' 
                        }
                    }
                }, 
                "Multiline,IgnoreCase")
            $markdown = [Regex]::Replace($markdown, 
                "\$\@\{([.\s\W\w\S]{1,})\}", 
                {
                    $a = $args 
                    $text = $a[0].Groups[1].ToString()
                    $text = $text.Replace("<pre>", "").Replace("</pre>", "")                    
                    $dataChunk = "@{$text}"

                    $theData = Import-PSData -DataString $dataChunk 


                    $scriptHtml = $theData | Out-HTML
                    
                    if ($scriptHtml) {
                        $scriptHtml
                    } else {
                        ("@{" + $args[0].Groups[1] + "}")
                    }
                }, 
                "Multiline,IgnoreCase")
                  

            
        }
        $markDown = $markdown -ireplace "$([Environment]::NewLine)", " $([Environment]::NewLine)" 
        #region Multiline Regex Replacement
        $replacements = @{
            Find = '^#{6}([^#].+)#{6}', '^#{6}([^#].+)'
            Replace = '<h6>$1</h6>
'
        }, @{
            Find = '^#{5}([^#].+)#{5}', '^#{5}([^#].+)'
            Replace = '<h5>$1</h5>
'
        }, @{
            Find = '^#{4}([^#].+)#{4}', '^#{4}([^#].+)'
            Replace = '<h4>$1</h4>
'
        }, @{
            Find = '^#{3}([^#].+)#{3}', '^#{3}([^#].+)'
            Replace = '<h3>$1</h3>
'
        }, @{
            Find = '^#{2}([^#].+)#{2}', '^#{2}([^#].+)'
            Replace = '<h2>$1</h2>
'
        }, @{
            Find = '^#{1}([^#].+)#{1}', '^#{1}([^#].+)'
            Replace = '<h1>$1</h1>
'
        }, @{
            # Horizontal rules
            Find = '^\* \* \*', '^- - -'
            Replace = "$([Environment]::NewLine)<HR/>$([Environment]::NewLine)"
        }, @{
            Find = '^(.+)\s={3,}'
            Replace = '<h1>$1</h1>'
        }, @{
            Find = '^(.+)\s-{3,}'
            Replace = '<h2>$1</h2>'
        } 
                     
        $Markdown = $Markdown.Trim()
        foreach ($r in $replacements) {
            foreach ($f in $r.find) {
                $regex =New-Object Regex $f, "Multiline, IgnoreCase"
                $Markdown  = $regex.Replace($markdown, $r.Replace)
            }            
        }
        #endregion Multiline Regex Replacement
        
        #region Singleline Regex Replacement
        $markdown = $markdown -ireplace 
            "$([Environment]::NewLine) $([Environment]::NewLine) $([Environment]::NewLine)", "$([Environment]::NewLine)<BR/><BR/>$([Environment]::NewLine)" -ireplace            
            '-{3,}', "$([Environment]::NewLine)<HR/>$([Environment]::NewLine)" -ireplace
            '\*{3,}', "$([Environment]::NewLine)<HR/>$([Environment]::NewLine)" -ireplace
            '\*\*(.+?)\*\*', '<b>$1</b>' -ireplace 
            '__(.+?)__', '<b>$1</b>' -ireplace 
            '\*(.+?)\*', '<i>$1</i>' -ireplace 
            '\s_(.+?)_\s', '<i>$1</i>' -ireplace 
            '`(.+)` ', '<span style="font-family:Consolas, Courier New, monospace">$1</span>&nbsp;'          
        #endregion Singleline Regex Replacement
        
        # build link dictionary
        $linkrefs = @{}
        $re_linkrefs = [regex]"\[(?<ref>[0-9]+)\]\:\s*(?<url>https?[^\s]+)"
        $markdown = $re_linkrefs.Replace($Markdown, {
            param($linkref)
            $linkrefs[$linkref.groups["ref"].value] = $linkref.groups["url"].value            
        })
        
        # handle links, images - embedded or referenced
        $re_links = [regex]"(?<image>!\s?)?\[(?<text>[^\]]+)](?:\((?<url>[^)]+)\)|\[(?<ref>\d+)])"
        $markdown = $re_links.Replace($markdown, {
            param($link);
            $url = $link.groups["url"].value
            if (-not $url) {
                # url did not match, so grab from dictionary
                $url = $linkrefs[$link.groups["ref"].value]
            }
            $text = $link.groups["text"].value

            if ($link.groups["image"].success) {
                # image
                $format = '<img src="{0}" alt="{1}" />'
                $format -f $url, $text
            } else {
                # href
                $format = '<a href="{0}">{1}</a>'
                if (-not $ConvertLink) {
                    $format -f "$url".Replace(" ", "%20"), $text
                } else {
                    Write-Link -Url $url -Caption $text -Button -Style @{
                        "font-size" = "small"
                    }
                }

            }
                        
        })

        $replacements = @(@{
            Find = '^>(.+)<BR/>'
            Replace = '<blockquote>$1</blockquote><br/>'
        })
        
        
        foreach ($r in $replacements) {
            foreach ($f in $r.find) {
                $regex =New-Object Regex $f, "Multiline, IgnoreCase"
                $Markdown  = $regex.Replace($markdown, $r.Replace)
            }            
        }
        
        $lines = @($Markdown -split ("[$([Environment]::NewLine)]") -ne "")
        $toReplace = @{}
        $inBlockQuote = $false
        $inNumberedList = $false
        $inList = $false
        $inInnerHTML = $false
        #region Fix Links and Code Sections
        $lines = @(foreach ($l in $lines) {
            
            if ($l -notlike "*#LinkTo*") {
                if ($l -match "^\d{1,}\.") {
                    if (-not $inNumberedList) {
                        "<ol>"
                    }  else {
                        "</li>"
                    }
                    $numberedListItemOpen = $true
                    "<li>" + $l.Substring($l.IndexOf(".") + 1) 
                    $inNumberedList = $true
                    continue
                } else {
                    if ($numberedListItemOpen) {
                        "</li></ol>"
                        $inList = $false
                        $numberedListItemOpen = $false
                    }
                }
                
                if ($l -match "^\s{0,3}\*{1}") {
                    if (-not $inList) {
                        "<ul>"
                    } else {
                        "</li>"
                    }
                    $listItemOpen = $true
                    "<li>" + $l.Substring($l.IndexOf("*") + 1)
                    $inList = $true
                    continue
                } else {
                    if ($listItemOpen) {
                        "</li></ul>"
                        $inList = $false
                        $listItemOpen = $false
                    }
                }               
                if ($l.StartsWith(">")) {
                    if (-not $inBlockQuote) {
                        "<blockquote>" + $l.TrimStart(">")                        
                    } else {
                        $l.TrimStart(">")
                    }
                    $inBlockQuote = $true
                    continue
                }

                
                if ((-not $inInnerHtml) -and $l.StartsWith("<")) {
                    $inInnerHTML = $true
                } elseif ($inInnerHtml -and $l.StartsWith("</")) {
                    $inInnerHTML = $false
                }


                                 
                if ($inBlockquote) {
                    if ($l -like "*<br/>*") {
                        $l -ireplace "<br/>", "</blockquote><br/>"
                        $inBlockQuote = $false
                    } else {
                        $l
                    }
                } elseif ($inNumberedList) {
                    if ($l -notlike "    *") {
                        if ($l -ne '<BR/>') {
                            "$l</ol>"   
                            $inNumberedList = $false
                        }
                    } else {
                        $l
                    }
                } elseif ($inList) {
                    if ($l -and $l -notlike "    *") {
                        if ($l -ne '<BR/>') {
                            "$l</ul>" 
                            $inList = $false
                        }                          
                    } else {
                        $l
                    }
                } else {
                    if (($l.StartsWith("    ") -and $l.Trim() -and $l -notlike "*<*")) {
                        if (-not $inCodeChunk) {
                            "<pre>"
                        }
                        $l.TrimStart("    ")
                        $inCodeChunk = $true
                        continue
                    } elseif ($InCodeChunk) {
                        $inCodeChunk = $false
                        "</pre>"
                    }
                    
                    if ($inCodeChunk) {
                        $inCodeChunk = $false
                        "</pre>"
                    }
                    $l                
                }
                
            } else {
                $first, $rest = $l -split ":"   
                $first = $first.Replace("#LinkTo", "").Trim()             
                $toReplace."@LinkTo${first}" = "$(($rest -join ':').Trim())"
            }
            
            
        }
        
        if ($numberedListItemOpen) {
            "</li></ol>"
            $inList = $false
            $numberedListItemOpen= $false
        }
        if ($listItemOpen) {            
            "</li></ul>"
            $inList = $false
            $listItemOpen = $false            
        })
        
        if ($inCodeChunk) {
            $inCodeChunk = $false
            $lines += "</pre>"
        }
        
        
        
        $markdown = $lines -join ([Environment]::NewLine)
        
        foreach ($tr in $toReplace.Getenumerator()) {
            if (-not $tr) {continue }
            $markDown = $markDown -ireplace "$($tr.Key)", $tr.Value
        }
        #endregion Fix Links and Code Sections


        
        if ($scriptAsPowershell) {
            $markdown = [Regex]::Replace($markdown, 
                "<pre[^>]*>([.\s\W\w\S]+)</pre>", 
                {
                    $scriptHtml = Write-ScriptHTML -Script $args[0].Groups[1] -ErrorAction SilentlyContinue
                    if ($scriptHtml) {
                        $scriptHtml
                    } else {
                        $args[0].Groups[1]
                    }
                }, 
                "Multiline,IgnoreCase")

        }
        
        
        if ($Splat) {
            $markdown = [Regex]::Replace($markdown, 
                "\@([\w-]{1,})(\@\{([.\s\W\w\S]+)\}){0,}", 
                {
                    $a = $args
                    $commandName = $args[0].Groups[1].ToString()
                    $splatIt = $args[0].Groups[2].ToString()
                    $commandName.Replace("<pre>", "").Replace("</pre>", "")                    
                    $splatIt = "$splatIt".Replace("<pre>", "").Replace("</pre>", "")                    
                    #$dataChunk = "@{$text}"

                    $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue

                    $invokeWebCommandParams = @{}
                    if ($pipeworksManifest -and $pipeworksManifest.WebCommand.$commandName) {
                        $invokeWebCommandParams = $pipeworksManifest.WebCommand.$commandName

                    } else {
                        $invokeWebCommandParams = @{ShowHelp=$true}
                    }


                    if ($splatIt) {
                        $theParams= & ([ScriptBlock]::Create("data { $dataChunk }"))                                                                                                    
                        $null = $invokeWebCommandParams.Remove("RunWithoutInput")
                        $defaults = @{} +$theParams 
                        if ($invokeWebCommandParams.ParameterDefaultValue) {
                            foreach ($kv in $invokeWebCommandParams.ParameterDefaultValue.GetEnumerator()) {
                                if (-not $defaults[$kv.Key]) {
                                    $defaults[$kv.Key] = $kv.Value
                                }
                            }
                        }

                        if ($invokeWebCommandParams.DefaultValue) {
                            foreach ($kv in $invokeWebCommandParams.DefaultValue.GetEnumerator()) {
                                if (-not $defaults[$kv.Key]) {
                                    $defaults[$kv.Key] = $kv.Value
                                }
                            }
                        }
                        $scriptHtml = Invoke-WebCommand -Command $command -ParameterDefaultValue $defaults -RunWithoutInput @invokeWebCommandParams
                    } else {                        
                        $scriptHtml = Invoke-WebCommand -Command $command @invokeWebCommandParams
                    }
                    

                    
                    
                    if ($scriptHtml) {
                        $scriptHtml
                    } else {
                        $args[0].Groups[1]
                    }
                }, 
                "Multiline,IgnoreCase")
                  
        }
  

        
        $markdown        
              
                                
			            
    }
} 