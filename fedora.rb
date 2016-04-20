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
  Resource('ZKCluster') do
    Type 'AWS::ECS::Cluster'
  end
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
  Resource('ZKService') do
    Type 'AWS::ECS::Service'
    DependsOn(['ZKAutoScale','ZKCluster'])
    Property('Cluster', Ref('ZKCluster'))
    Property('DesiredCount', 1)
    Property('Role', 'ecsServiceRole')
#    Property('TaskDefinition', FnJoin('', ['arn:aws:ecs:', Ref('AWS::Region'), ':', Ref('AWS::AccountId'), ':task-definition/', Ref('ZKCluster'), ':1']))
    Property('TaskDefinition', 'zookeeper:1')
    Property('LoadBalancers',
      [{
        ContainerName: 'zookeeper',
        ContainerPort: 2181,
        LoadBalancerName: Ref('ZKLoadBalancer')
      }])
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
  end
  Resource('ZKSecurityGroupIngress') do
    Type('AWS::EC2::SecurityGroupIngress')
    Property('GroupName', Ref('ZKSecurityGroup'))
    Property('IpProtocol', 'tcp')
    Property('ToPort', '2181')
    Property('FromPort', '2181')
    Property('CidrIp', '172.31.0.0/16')
  end
  Resource('ZKAutoScale') do
    Type('AWS::AutoScaling::AutoScalingGroup')
    Property('AvailabilityZones', FnGetAZs(''))
    Property('LaunchConfigurationName', Ref('ZKLaunchConfig'))
    Property('MinSize', '1')
    Property('MaxSize', '1')
    Property('LoadBalancerNames', [ Ref('ZKLoadBalancer')])
  end
  Resource('ZKLaunchConfig') do
    Type('AWS::AutoScaling::LaunchConfiguration')
    Property('KeyName', 'zookeeper')
    Property('ImageId', 'ami-67a3a90d')
    Property('UserData', FnBase64(FnJoin('', [
  "#!/bin/bash\n",
  "echo ECS_CLUSTER=",
  Ref('ZKCluster'),
  " >> /etc/ecs/ecs.config\n"])))
    Property('InstanceType', 't2.small')
  end

  # Output('FedoraURL') do
  #   Value(FnGetAtt('FedoraDev', 'EndpointURL'))
  # end
  # Output('ZKTaskDef') do
  #   Value(Ref('ZKTask'))
  # end
  Output('ZKTask') do
    Value(FnJoin('', ['arn:aws:ecs:', Ref('AWS::Region'), ':', Ref('AWS::AccountId'), ':task-definition/', Ref('ZKCluster'), ':1']))
  end
end
