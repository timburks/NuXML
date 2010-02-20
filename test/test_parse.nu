(load "NuXML")

(class TestParse is NuTestCase
     (- testFromXML is
        (set xmlString <<-END
<fruits>
<apple version="4.0" language="english">Red Delicious</apple>
<orange>Cara Cara</orange></fruits>END)
        (set golden (array "fruits"
                           (array "apple" (dict version:"4.0" language:"english") "Red Delicious")
                           (array "orange" "Cara Cara")))
        (assert_equal golden (xmlString xmlValue))))



