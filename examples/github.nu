(load "NuXML")


(set string (NSString stringWithShellCommand:"curl -s http://github.com/api/v1/xml/timburks/NuXML/commits/master"))

;(set string (NSString stringWithContentsOfFile:"examples/github.xml"))
(set document (string xmlValue))

(set commits (document xmlChildrenWithName:"commit"))
(commits each:
         (do (commit)
             (set author (commit xmlChildWithName:"author"))
             (set name (author xmlNodeValueOfChildWithName:"name"))
             (set committed-date (commit xmlNodeValueOfChildWithName:"committed-date"))
             (set message (commit xmlNodeValueOfChildWithName:"message"))
             (puts "------------")
             (puts (+ "COMMIT: " name " " committed-date))
             (puts message)))
(puts "------------")


