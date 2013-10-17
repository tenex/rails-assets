require 'spec_helper'

module Build
  describe BowerComponent do
    context '#from_bower for latest version' do
      let(:subject) {
        silence_stream(STDOUT) do
          BowerComponent.from_bower('angular-tagger')
        end
      }

      it 'properly generates BowerComponent' do
        expect(subject).to be_a(BowerComponent)
      end

      it 'properly extract dependencies' do
        expect(subject.dependencies).to be_a(Hash)
      end

      it 'properly extract main files' do
        expect(subject.main).to be_an(Array)
      end

      it 'properly extracts description' do
        expect(subject.description).to be_a(String)
      end
    end

    context '#from_bower for specific version' do
      let(:subject) {
        silence_stream(STDOUT) do
          BowerComponent.from_bower('angular-tagger', '0.1.2')
        end
      }

      it 'properly generates BowerComponent' do
        expect(subject).to be_a(BowerComponent)
      end

      it 'properly extract dependencies' do
        expect(subject.dependencies).to be_a(Hash)
      end

      it 'properly extract main files' do
        expect(subject.main).to be_an(Array)
      end

      it 'properly extracts description' do
        expect(subject.description).to be_a(String)
      end
    end
  end
end
