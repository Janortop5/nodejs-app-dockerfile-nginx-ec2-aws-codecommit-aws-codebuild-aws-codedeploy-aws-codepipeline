# Use this code snippet in your app.
# If you need more information about configurations
# or implementing the sample code, visit the AWS docs:
# https://aws.amazon.com/developer/language/python/

import boto3
from botocore.exceptions import ClientError


def get_secret():

    secret_name = "docker_details"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']

    # Your code goes here.

def main():
    try:
        # Get the secret
        secret_dict = get_secret()
        
        # Export secrets as environment variables
        for key, value in secret_dict.items():
            os.environ[key] = value
        
        print("Secrets exported as environment variables")
        
        # Check if Docker credentials are available
        if 'docker_username' in secret_dict and 'docker_password' in secret_dict:
            print("Docker credentials found. Attempting to log in...")
            
            # Use subprocess to run the docker login command
            try:
                result = subprocess.run(
                    ["docker", "login", 
                     "-u", secret_dict['docker_username'],
                     "-p", secret_dict['docker_password']],
                    check=True,
                    capture_output=True,
                    text=True
                )
                print("Docker login successful")
            except subprocess.CalledProcessError as e:
                print(f"Docker login failed: {e.stderr}")
                raise
        else:
            print("Docker credentials not found in the secret")
        
        # Add any additional steps that require Docker access here
        
    except Exception as e:
        print(f"An error occurred: {e}")
        raise e

if __name__ == "__main__":
    main()
