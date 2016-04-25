CloudFormation do
  AWSTemplateFormatVersion('2010-09-09')
#  Description('HyBox Stack')

  # Fedora EB
  # Resource('Fedora') do
  #   Type('AWS::ElasticBeanstalk::Application')
  #   Property('Description', 'AWS ElasticBeanstalk Fedora')
  # end
  # Resource('Fedora450') do
  #   Type('AWS::ElasticBeanstalk::ApplicationVersion')
  #   Property('ApplicationName', Ref('Fedora'))
  #   Property('Description', 'AWS ElasticBeanstalk Fedora v4.5.0')
  #   Property('SourceBundle', {
  #     'S3Bucket' => 'fcrepo4-wars',
  #     'S3Key'    => 'fcrepo-webapp-4.5.0.war'
  #   })
  # end
  # Resource('FedoraConfig') do
  #   Type('AWS::ElasticBeanstalk::ConfigurationTemplate')
  #   Property('ApplicationName', Ref('Fedora'))
  #   Property('Description', 'AWS ElasticBeanstalk Fedora Configuration')
  #   Property('OptionSettings', [
  #     {
  #       'Namespace'  => 'aws:autoscaling:asg',
  #       'OptionName' => 'MinSize',
  #       'Value'      => '1'
  #     },
  #     {
  #       'Namespace'  => 'aws:autoscaling:asg',
  #       'OptionName' => 'MaxSize',
  #       'Value'      => '1'
  #     },
  #     {
  #       'Namespace'  => 'aws:elasticbeanstalk:environment',
  #       'OptionName' => 'EnvironmentType',
  #       'Value'      => 'LoadBalanced'
  #     }
  #   ])
  #   Property('SolutionStackName', '64bit Amazon Linux 2016.03 v2.1.0 running Tomcat 8 Java 8')
  # end
  # Resource('FedoraDev') do
  #   Type('AWS::ElasticBeanstalk::Environment')
  #   Property('ApplicationName', Ref('Fedora'))
  #   Property('Description', 'AWS ElasticBeanstalk Fedora for development')
  #   Property('VersionLabel', Ref('Fedora450'))
  #   Property('TemplateName', Ref('FedoraConfig'))
  # end

  #######
  # ZK
  #######
  # Resource('ZKCluster') do
  #   Type 'AWS::ECS::Cluster'
  # end
  # Resource('ZKTask') do
  #   Type 'AWS::ECS::TaskDefinition'
  #   Property('ContainerDefinitions',
  #     [{
  #       Name: 'ZK',
  #       Cpu: 10,
  #       Essential: true,
  #       Image: 'jplock/zookeeper:latest',
  #       Memory: 1024,
  #       PortMappings: [{
  #         ContainerPort: 2181,
  #         HostPort: 2181,
  #         Protocol: 'tcp' }]
  #     }])
  # end
  # Resource('ZKServiceRole') do
  #   Type('AWS::IAM::Role')
  #   Property('AssumeRolePolicyDocument', {
  #     'Statement' => [{
  #       'Action'    => ['sts:AssumeRole'],
  #       'Effect'    => 'Allow',
  #       'Principal' => {
  #         'Service' => ['ec2.amazonaws.com']
  #       }
  #     }]
  #   })
  #   Property('Path', '/')
  # end
  # Resource('ZKServiceRolePolicy') do
  #   Type('AWS::IAM::Policy')
  #   Property('PolicyName', 'ZKecsServiceRole')
  #   Property('PolicyDocument', {
  #     'Statement' => [{
  #       'Action'   => '*',
  #       'Effect'   => 'Allow',
  #       'Resource' => '*'
  #     }]
  #   })
  #   Property('Roles', [ Ref('ZKServiceRole')])
  # end
  # Resource('ZKService') do
  #   Type 'AWS::ECS::Service'
  #   DependsOn(['ZKAutoScale','ZKCluster'])
  #   Property('Cluster', Ref('ZKCluster'))
  #   Property('DesiredCount', 1)
  #   Property('Role', 'ecsServiceRole')
  #   # Property('TaskDefinition', FnJoin('', ['arn:aws:ecs:', Ref('AWS::Region'), ':', Ref('AWS::AccountId'), ':task-definition/', Ref('ZKCluster'), ':1']))
  #   Property('TaskDefinition', 'zookeeper:1')
  #   Property('LoadBalancers',
  #     [{
  #       ContainerName: 'zookeeper',
  #       ContainerPort: 2181,
  #       LoadBalancerName: Ref('ZKLoadBalancer')
  #     }])
  # end
  Resource('ZKAutoScale') do
    Type('AWS::AutoScaling::AutoScalingGroup')
    Property('AvailabilityZones', FnGetAZs(''))
    Property('VPCZoneIdentifier', ['subnet-4eb52273', 'subnet-14a3553e', 'subnet-7d2cd625', 'subnet-ed0aaa9b'])
    Property('LaunchConfigurationName', Ref('ZKLaunchConfig'))
    Property('MinSize', '1')
    Property('MaxSize', '1')
    Property('LoadBalancerNames', [ Ref('ZKLoadBalancer')])
  end
  Resource('ZKLaunchConfig') do
    Type('AWS::AutoScaling::LaunchConfiguration')
    Property('KeyName', 'zookeeper')
    Property('SecurityGroups', [Ref('ZKSecurityGroup')])
    Property('ImageId', 'ami-67a3a90d')
    Property('AssociatePublicIpAddress', 'true')
  #   Property('UserData', FnBase64(FnJoin('', [
  # "#!/bin/bash\n",
  # "echo ECS_CLUSTER=",
  # Ref('ZKCluster'),
  # " >> /etc/ecs/ecs.config\n"])))
    Property('InstanceType', 't2.small')
    Property('IamInstanceProfile', 'ecsInstanceRole')
  end
  Resource('ZKLoadBalancer') do
    Type('AWS::ElasticLoadBalancing::LoadBalancer')
    Property('AvailabilityZones', FnGetAZs(''))
    Property('Listeners',
      [{
        'InstancePort'     => 2181,
        'LoadBalancerPort' => 2181,
        'Protocol'         => 'tcp'
      }])
  end
  Resource('ZKSecurityGroup') do
    Type('AWS::EC2::SecurityGroup')
    Property('GroupDescription', 'ZK Cluster Security Group')
    Property('SecurityGroupIngress',
      [{
        'IpProtocol' => 'tcp',
        'ToPort' => '2181',
        'FromPort' => '2181',
        'CidrIp' => '0.0.0.0/0'
      }])
  end

  # Output('FedoraURL') do
  #   Value(FnGetAtt('FedoraDev', 'EndpointURL'))
  # end
  # Output('ZKTaskDef') do
  #   Value(Ref('ZKTask'))
  # end
  # Output('ZKTask') do
  #   Value(FnJoin('', ['arn:aws:ecs:', Ref('AWS::Region'), ':', Ref('AWS::AccountId'), ':task-definition/', Ref('ZKCluster'), ':1']))
  # end
  Output('URL') do
    Description 'The URL of the load balancer'
    Value FnJoin('', ['http://', FnGetAtt('ZKLoadBalancer', 'DNSName')])
  end
end
