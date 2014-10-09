//
// AudioFile.swift
// Coliseu
//
// Copyright (c) 2014 Ricardo Pereira (http://ricardopereira.eu)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// ? - Test for MetaData
import AVFoundation

class AudioFile
{
    let title: String
    let fileName: String
    var fileSize: Int = 0
    var length: Float = 0.0
    var duration: NSTimeInterval = 0
    var path: NSURL?
    var index: Int = 0

    required init(_ title: String, _ fileName: String)
    {
        self.title = title
        self.fileName = fileName
    }

    convenience init(url: NSURL)
    {
        let fileAsset = AVURLAsset(URL: url, options: nil)
        var title: String = "Song"

        // ToDo
        for metadataFormat in fileAsset.availableMetadataFormats {
            if let metadataList = fileAsset.metadataForFormat(metadataFormat as String) {
                for metadataItem in metadataList
                {
                    if metadataItem.commonKey == nil {
                        continue
                    }
                    let commonKey = metadataItem.commonKey!

                    if commonKey == nil {
                        continue
                    }

                    switch commonKey! {
                    case "artword":
                        NSLog("Artwork")
                    case "title":
                        title = metadataItem.value!!
                    default:
                        NSLog("none")
                    }
                }
            }
        }

        self.init(title, url.lastPathComponent)
        path = url
    }
}
