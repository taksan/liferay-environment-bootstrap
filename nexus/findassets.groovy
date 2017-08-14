import org.sonatype.nexus.repository.storage.Asset
import org.sonatype.nexus.repository.storage.Query
import org.sonatype.nexus.repository.storage.StorageFacet

import groovy.json.JsonOutput
import groovy.json.JsonSlurper

def request = new JsonSlurper().parseText(args);
assert request.repoName: 'repoName parameter is required';
assert request.pattern: 'pattern parameter is required';

def repo = repository.repositoryManager.get(request.repoName);
StorageFacet storageFacet = repo.facet(StorageFacet);
def tx = storageFacet.txSupplier().get();

tx.begin();

Iterable<Asset> assets = tx.
    findAssets(Query.builder().where('name like').param(request.pattern).build(), [repo]);
def urls = assets.collect { "/repository/${repo.name}/${it.name()}" };

tx.commit();

return JsonOutput.toJson(urls);
//return urls;
