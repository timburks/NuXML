;; source files
(set @m_files     (filelist "^objc/.*.m$"))

(set SYSTEM ((NSString stringWithShellCommand:"uname") chomp))
(case SYSTEM
      ("Darwin"
               (set @arch (list "i386"))
               (set @cflags "-g -std=gnu99 -fobjc-gc -DDARWIN -I /usr/include/libxml2")
               (set @ldflags  "-framework Foundation -lxml2"))
      ("Linux"
              (set @arch (list "i386"))
              (set gnustep_flags ((NSString stringWithShellCommand:"gnustep-config --objc-flags") chomp))
              (set gnustep_libs ((NSString stringWithShellCommand:"gnustep-config --base-libs") chomp))
              (set @cflags "-g -std=gnu99 -DLINUX -I/usr/include/libxml2 #{gnustep_flags}")
              (set @ldflags "#{gnustep_libs} -lxml2"))
      (else nil))

;; framework description
(set @framework "MinimalXML")
(set @framework_identifier "nu.programming.minimalxml")
(set @framework_creator_code "????")

(compilation-tasks)
(framework-tasks)

(task "default" => "framework")


