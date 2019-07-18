# Recipe Finder

A recipe search API that allows to manage/search recipes stored in Elasticsearch.

## Install Elasticsearch

### Pull and run the image:

```
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.2.0
```
(more: see https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)

On the first start this will pull the image and run it; on subsequent starts, it will run the downloaded image

## Commands

### DeleteIndexCommand

Deletes the index {indexName} from Elasticsearch.

Usage:  `vapor run elastic:deleteIndex {indexName}`
Example:  `vapor run elastic:deleteIndex recipes`

### ImportRecipesCommand

Imports recipes from a json file within the `Resources` folder into Elasticsearch index `recipes`.

Usage:  `elastic:importRecipes {fileName}`
Example:  `elastic:importRecipes recipes.json`

## Todos

- [ ] Wrap ElasticsearchClient into a Vapor Service
- [ ] Add bigger set of recipes for the initial import
- [ ] Decide if we want to use bulk import for the intial import or leave this for another tutorial
