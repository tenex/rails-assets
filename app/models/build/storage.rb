module Build
  # Stores the finished gem in an appropriate place
  class Storage
    def initialize
      @client = Aws::S3::Client.new(
        access_key_id: Figaro.env.aws_access_key,
        secret_access_key: Figaro.env.aws_secret_access_key,
        endpoint: 'https://nyc3.digitaloceanspaces.com',
        region: 'us-east-1' # required by aws sdk but unused
      )
    end

    def put_bucket(name, content)
      @client.put_object(bucket_params(name, content))
    end

    def bucket_params(name, content)
      {
        bucket: Figaro.env.bucket,
        key: name,
        body: content,
        acl: 'public-read'
      }
    end
  end
end
