(load "NuXML")

(set xmlString <<-END
<fruits>
  <apple version="3.0" language="english">Red Delicious</apple>
  <orange>Cara Cara&lt;More&gt;</orange>
</fruits>
END)

(puts ((xmlString xmlValue) description))

(set files (array "examples/github.xml"
                  "examples/namespace.xml"
                  "examples/200779.xml"))

(files each:
       (do (file)
           (set string (NSString stringWithContentsOfFile:file))
           (set result (string XMLValue))
           (puts (result description))))
