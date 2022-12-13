import {Injectable} from '@angular/core';
import {EntityCollectionServiceBase, EntityCollectionServiceElementsFactory} from '@ngrx/data';
import {Task} from '../model/task';
import {EntityNamesEnum} from '../utils/store/entity-names.enum';

@Injectable()
export class TasksEntityService extends EntityCollectionServiceBase<Task> {

  constructor(serviceElementsFactory: EntityCollectionServiceElementsFactory) {
    super(EntityNamesEnum.task, serviceElementsFactory);
  }
}
