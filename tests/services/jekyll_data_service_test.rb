require_relative '../test_helper'

class JekyllDataServiceTest < BaseGemTest
  def setup
    @jekyll_data_service = Services::JekyllDataService.new('msoe-sg/msoe-sg-website', 'auth token')
  end

  def test_get_jekyll_data_as_hash_should_return_yaml_data_as_hash_when_given_valid_file_name
    # Arrange
    yaml_content = %( - id: 1
- prop1: 2

- id: 2
- prop1: 2)
    
    GithubService.any_instance.expects(:get_jekyll_data_as_hash).with('_data/data.yml', 'ref').returns(yaml_content)

    # Act
    result = @jekyll_data_service.get_jekyll_data_as_hash('data.yml', 'ref')

    # Assert
    assert_equal 2, result.count

    assert_equal 1, result[0]['id']
    assert_equal 2, result[0]['prop1']

    assert_equal 2, result[1]['id']
    assert_equal 2, result[1]['prop1']
  end
end