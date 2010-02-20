(load "NuXML")

(set string (NSString stringWithContentsOfFile:"yahoo.xml"))
(set document (string xmlValue))

(set result (document xmlChildWithName:"Result"))

(set latitude (result xmlNodeValueOfChildWithName:"Latitude"))
(set longitude (result xmlNodeValueOfChildWithName:"Longitude"))

(puts (+ latitude "," longitude))



