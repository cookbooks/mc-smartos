class Chef
  class Provider
    class User 
      class Useradd < Chef::Provider::User
        
        def check_lock
          case node[:platform]
          when "smartos"
            status = popen4("passwd -s #{@new_resource.username}") do |pid, stdin, stdout, stderr|
              status_line = stdout.gets.split(' ')
              case status_line[1]
              when /^P/
                @locked = false
              when /^N/
                @locked = false
              when /^L/
                @locked = true
              end
            end
          else
            status = popen4("passwd -S #{@new_resource.username}") do |pid, stdin, stdout, stderr|
              status_line = stdout.gets.split(' ')
              case status_line[1]
              when /^P/
                @locked = false
              when /^N/
                @locked = false
              when /^L/
                @locked = true
              end
            end
          end

          unless status.exitstatus == 0
            raise_lock_error = false
            # we can get an exit code of 1 even when it's successful on rhel/centos (redhat bug 578534)
            if status.exitstatus == 1 && ['redhat', 'centos'].include?(node[:platform])
              passwd_version_status = popen4('rpm -q passwd') do |pid, stdin, stdout, stderr|
                passwd_version = stdout.gets.chomp

                unless passwd_version == 'passwd-0.73-1'
                  raise_lock_error = true
                end
              end
            else
              raise_lock_error = true
            end

            raise Chef::Exceptions::User, "Cannot determine if #{@new_resource} is locked!" if raise_lock_error
          end

          @locked
        end
        
        def lock_user
          run_command(:command => "usermod -L #{@new_resource.username}")
        end
        
        def unlock_user
          case node[:platform]
          when "smartos"
            run_command(:command => "passwd -u #{@new_resource.username}")
          else
            run_command(:command => "usermod -U #{@new_resource.username}")
          end
        end

        def useradd_options
          case node[:platform]
          when "smartos"
            opts = ''
            opts << " -m" if updating_home? && managing_home_dir?
            # opts << " -r" if @new_resource.system
            opts
          else
            opts = ''
            opts << " -m" if updating_home? && managing_home_dir?
            opts << " -r" if @new_resource.system
            opts
          end
        end

      end
    end
  end
end