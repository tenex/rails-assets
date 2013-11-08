require 'spec_helper'

module Build
  describe BowerError do
    context '#from_shell_error' do
      let(:stderr) {
        <<-EOF
          [{
            "code": "ENOTFOUND",
            "data": {
              "endpoint": {
                "name": "",
                "source": "asdfa",
                "target": "*"
              }
            },
            "id": "ENOTFOUND",
            "level": "error",
            "message": "Package asdfa not found",
            "details": "Error: Package asdfa not found"
          }]
        EOF
      }

      let(:shell_error) { ShellError.new(stderr) }

      it 'extracts error message from stderr' do
        expect(BowerError.from_shell_error(shell_error).message).
          to eq('Package asdfa not found') 
      end

      it 'extracts error details from stderr' do
        expect(BowerError.from_shell_error(shell_error).details).
          to eq('Error: Package asdfa not found') 
      end
    end
  end
end
