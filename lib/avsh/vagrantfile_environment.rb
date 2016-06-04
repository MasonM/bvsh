module Avsh
  # This module is a horrible hack to parse out the relevant config details from
  # a Vagrantfile, without incurring the overhead of loading Vagrant. It uses a
  # binding object to eval the Vagrantfile in this module, which will
  # communicate with the dummy Vagrant module below.
  module VagrantfileEnvironment
    def self.evaluate(vagrantfile_path, vm_name)
      # The dummy_configure object will be used to collect the config details.
      # We need to set it as a class variable on Vagrant, since we can't tell
      # the Vagrantfile to use a specific instance of Vagrant.
      dummy_configure = Configure.new(vm_name)
      Vagrant.class_variable_set(:@@configure, dummy_configure)

      begin
        # Eval the Vagrantfile with this module as the execution context
        binding.eval(File.read(vagrantfile_path), vagrantfile_path)
      # rubocop:disable Lint/RescueException:
      rescue Exception => e
        raise VagrantfileEvalError.new(vagrantfile_path, e)
      end

      dummy_configure
    end

    # Dummy Vagrant module that stubs out everything except what's needed to
    # extract config details.
    module Vagrant
      # rubocop:disable Style/PredicateName
      def self.has_plugin?(*)
        # Just lie and say we have the plugin, because a Vagrantfile that calls
        # this is probably doing dependency checking, and will terminate if this
        # doesn't return true. However, this could result in unwanted behavior
        # if the Vagrantfile does weird things like ensuring a plugin DOESN'T
        # exist. I've never seen that before, though.
        true
      end

      def self.configure(*)
        # Give the provided block the dummy_configure object set above in
        # DummyVagrantEnvironment.find_synced_folders
        yield @@configure
      end

      def self.method_missing(*) end # ignore everything else
    end

    # Dummy Configure object to collect the config details.
    class Configure
      attr_reader :synced_folders

      def initialize(vm_name)
        @vm_name = vm_name
        @synced_folders = {}
      end

      def synced_folder(src, dest, *_args)
        @synced_folders[src] = dest unless @synced_folders.include?(src)
      end

      def define(vm_name, *_args)
        if vm_name.to_s == @vm_name.to_s
          yield self
        else
          # The guest machine is different than the VM we care about, so give it
          # a new Configure object that'll be thrown away at the end.
          yield Configure.new(nil)
        end
      end

      # Ensure this object continues to be used when defining a multi-machine
      # setup, and ignore any other methods, since they don't matter.
      def method_missing(*)
        yield self if block_given?
        self
      end
    end
  end
end
